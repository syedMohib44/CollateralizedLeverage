const HDWalletProvider = require('@truffle/hdwallet-provider');

require('dotenv').config();  // Store environment-specific variable from '.env' to process.env

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      gasPrice: 10000000000,
      gas: 10000000
    },
    mumbai: {
      //https://matic-mumbai.chainstacklabs.com/
      provider: () => new HDWalletProvider("PRIVATE-KEY",
        `https://rpc-mumbai.maticvigil.com/v1/4c9a2f5a92d686c283f4f466f5e81fafa95f063a`),
      network_id: 80001,
      // gas: 6000000,           // Gas sent with each transaction (default: ~6700000)
      // gasPrice: 7000000000,  // 3 gwei (in wei) (default: 100 gwei)
      confirmations: 2,
      networkCheckTimeout: 1000000,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.6.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200   // Optimize for how many times you intend to run the code
        }
      }
    }
  }
};