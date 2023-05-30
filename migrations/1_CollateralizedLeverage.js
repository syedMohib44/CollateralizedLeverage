const CollateralizedLeverage = artifacts.require('CollateralizedLeverage');

module.exports = async function (deployer) {
   await deployer.deploy(CollateralizedLeverage, '0x0fa8781a83e46826621b3bc094ea2a0212e71b23', '0xe675d762199E0F7BD907B67E76f04403088ff5aC');
};