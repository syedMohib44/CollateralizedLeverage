import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

pragma solidity ^0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

contract CollateralizedLeverage is BasicAccessControl {
    using SafeERC20 for IERC20;

    struct Loan {
        uint256 amount;
        uint256 lockPeriod;
        uint256 borrowedAt;
        bool active;
    }

    mapping(address => Loan) public loans;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public collateral;

    uint256 public interestRate = 5; // 5% per month
    uint256 public collateralMultiplier = 50; // 50% collateral multiplier
    uint256 public maxLoanPeriod = 12; // Maximum advised loan period in months
    bool public isTesting = true;

    //usdc: 0x0fa8781a83e46826621b3bc094ea2a0212e71b23
    IERC20 public usdc;
    IERC20 public token;

    event LoanCreated(
        address indexed borrower,
        uint256 amount,
        uint256 lockPeriod
    );
    event LoanRepaid(
        address indexed borrower,
        uint256 amount,
        uint256 interest
    );
    event CollateralClaimed(
        address indexed lender,
        address indexed borrower,
        uint256 amount
    );

    event Transfer(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    constructor(address _usdc, address _token) public {
        usdc = IERC20(_usdc);
        token = IERC20(_token);

        usdcMaxCap = 1 * 10 ** 18;
        tokenMaxCap = 1 * 10 ** 18;
    }

    function setIsTesting(bool _isTesting) external onlyModerators {
        _isTesting = isTesting;
    }

    function setUSDC(address _usdc) external onlyModerators {
        usdc = IERC20(_usdc);
    }

    function setToken(address _token) external onlyModerators {
        token = IERC20(_token);
    }

    function setCollateralMultiplier(
        uint256 _collateralMultiplier
    ) external onlyModerators {
        collateralMultiplier = _collateralMultiplier;
    }

    function setInterestRate(uint256 _interestRate) external onlyModerators {
        interestRate = _interestRate;
    }

    uint256 tokensInUsdc = 0;
    // Token price per dollar
    uint256 public tokenPrice = 0;
    // Usdc price per dollar
    uint256 public usdcPrice = 0;

    uint256 tokenCap = 0;
    uint256 usdcCap = 0;
    uint256 tokenMaxCap = 0;
    uint256 usdcMaxCap = 0;

    /**
        @param _amount: uint256 => Amount in USDC 
        @return Price in TOKEN
        Disctiption: Pass 1 USDC get value in TOKEN
    */
    function getTokenRatesFromUsdc(
        uint256 _amount
    ) public view returns (uint256) {
        uint256 usdcP = usdcPrice * _amount;
        uint256 tokenP = tokenPrice * 10 ** 18;

        uint256 rate = usdcP / tokenP;
        if (rate <= 0) {
            rate = (usdcP * 10 ** 18) / tokenP;
            rate = (rate < usdcCap) ? usdcCap : rate;
            return rate;
        }
        rate = rate * 10 ** 18;
        rate = (rate < usdcCap) ? usdcCap : rate;

        return rate;
    }

    /**
        @param _amount: uint256 => Amount in TOKEN 
        @return Price in USDC
        Disctiption: Pass 1 TOKEN get value in USDC
    */
    function getUsdcRatesFromToken(
        uint256 _amount
    ) public view returns (uint256) {
        uint256 tokenP = tokenPrice * _amount;
        uint256 usdcP = usdcPrice * 10 ** 18;

        uint256 rate = tokenP / usdcP;
        if (rate <= 0) {
            rate = (tokenP * 10 ** 18) / usdcP;
            rate = (rate < tokenCap) ? tokenCap : rate;
            return rate;
        }
        rate = (rate < tokenCap) ? tokenCap : rate;

        return rate;
    }

    function updatePrices(
        uint256 _tokenPrice,
        uint256 _usdcPrice
    ) external onlyModerators {
        if (_tokenPrice < tokenCap) tokenPrice = _tokenPrice;
        if (_usdcPrice < usdcCap) usdcPrice = _usdcPrice;

        usdcPrice = _usdcPrice;
        tokenPrice = _tokenPrice;
    }

    function setCapToken(uint256 _tokenCap) external onlyModerators {
        require(_tokenCap < tokenMaxCap, "Cannot put cap lesser than 0");
        tokenCap = _tokenCap;
    }

    function setCapUsdc(uint256 _usdcCap) external onlyModerators {
        require(_usdcCap <= usdcMaxCap, "Cannot put cap lesser than 0");
        usdcCap = _usdcCap;
    }

    function setMaxCapToken(uint256 _tokenMaxCap) external onlyOwner {
        tokenMaxCap = _tokenMaxCap;
    }

    function setMaxCapUsdc(uint256 _usdcMaxCap) external onlyOwner {
        usdcMaxCap = _usdcMaxCap;
    }

    function borrow(uint256 _amount, uint256 lockPeriod) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            lockPeriod > 0 && lockPeriod <= maxLoanPeriod,
            "Lock period must be between 1 and 12"
        );

        require(
            loans[msg.sender].active == false,
            "Borrower already has an active loan"
        );
        require(token.balanceOf(msg.sender) >= _amount, "Balance is low");

        uint256 tokenRate = getUsdcRatesFromToken(_amount);
        balances[msg.sender] += tokenRate;

        uint256 borrowedAmount = (tokenRate * collateralMultiplier) / 100;

        require(borrowedAmount > 0, "Price of token is too low");

        require(balances[msg.sender] >= borrowedAmount, "Insufficient balance");

        balances[msg.sender] -= borrowedAmount;

        uint256 currentTime = now;

        loans[msg.sender] = Loan(
            borrowedAmount,
            currentTime + (lockPeriod * (30 days)),
            currentTime,
            true
        );

        if (!isTesting) {
            token.transferFrom(msg.sender, address(this), _amount);
            usdc.transferFrom(address(this), msg.sender, borrowedAmount);
        }

        emit LoanCreated(msg.sender, borrowedAmount, lockPeriod);
    }

    function balanceOfToken() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function balanceOfUSDC() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function withdrawToken(uint256 _amount) external onlyModerators {
        token.transferFrom(address(this), msg.sender, _amount);
    }

    function withdrawUSDC(uint256 _amount) external onlyModerators {
        usdc.transferFrom(address(this), msg.sender, _amount);
    }

    function repay() external {
        Loan memory loan = loans[msg.sender];
        require(loan.active, "No active loan");
        uint256 currentTime = now;
        require(loan.lockPeriod > currentTime, "Time expired");

        uint256 intRate = 0;
        uint256 loanPeriod = (currentTime - loan.borrowedAt) / 30 days;
        loanPeriod = (loanPeriod > 12) ? 12 : loanPeriod;

        if (loan.lockPeriod > currentTime) intRate = (loan.lockPeriod - currentTime) / 30 days;
        if (intRate > 0) intRate = 10;

        uint256 interest = (loan.amount * interestRate * loanPeriod) / 100;
        uint256 totalAmount = loan.amount - interest;

        balances[msg.sender] += totalAmount;
        delete loans[msg.sender];

        emit LoanRepaid(msg.sender, loan.amount, interest);
    }

    function withdrawBalance() external {
        uint balance = balances[msg.sender];
        if (!isTesting && balance > 0)
            usdc.transferFrom(address(this), msg.sender, balance);
        Transfer(address(this), msg.sender, balance);
    }

    function claimCollateral() external {
        Loan memory loan = loans[msg.sender];
        require(loan.active, "No active loan");

        uint256 collateralValue = (loan.amount * collateralMultiplier) / 100;
        uint256 totalAmount = loan.amount -
            ((loan.amount * interestRate * maxLoanPeriod) / 100);

        require(
            collateralValue < totalAmount,
            "Collateral value is higher than principal plus interest"
        );
        totalAmount -= collateralValue;

        balances[msg.sender] += totalAmount;
        delete loans[msg.sender];

        emit CollateralClaimed(msg.sender, address(this), loan.amount);
    }
}
