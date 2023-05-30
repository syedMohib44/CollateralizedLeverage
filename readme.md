# Prerequiste
> npm install
> truffle init


# Run
> truffle migrate --network mumbai
> truffle networks --clean


# Deploy
> truffle develop
> truffle deploy (To compile locally)
> truffle migrate -f 1 --to 1 --network mumbai


# Flatten file
> node flattener --flatten=filename

# Node
> Added coin-geecko.js which works as oracle we can run it every 8 hour so token and stable coin prices remain up-to-date, to run node coin-geecko.js