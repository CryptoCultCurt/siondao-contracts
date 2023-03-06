require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  namedAccounts: process.env.namedAccounts,
  defaultNetwork: 'hardhat',
  networks: {
    bsc: {
        url: "https://rpc.ankr.com/bsc/e055afb958402bd2a97b039ae8452bb10b880d67994b18a3383ef4c34cf05b49",
        chainId: 56,
        gasPrice: 20000000000,
        accounts: {mnemonic: process.env.MNEMONIC},
        verify: {
          etherscan: {
            apiKey: process.env.ETHERSCAN_API_BSC
          }
        }
    },
    testnet: {
        url: "https://data-seed-prebsc-1-s1.binance.org:8545",
        chainId: 97,
        gasPrice: 20000000000,
        gasMultiplier: 2,
        accounts: {mnemonic: process.env.MNEMONIC},
        verify: {
          etherscan: {
            apiKey: process.env.ETHERSCAN_API_BSC
          }
        }
      },
    },
  etherscan: {
    apiKey:process.env.ETHERSCAN_API_BSC
  },
  namedAccounts : {
    deployer: {
        default: 0
    }
  }
     // gasReporter: process.env.gasReport
};

