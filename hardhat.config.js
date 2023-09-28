require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
// require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers");
require('./utils/hardhat-ovn');
require('dotenv').config()
// require('hardhat-contract-sizer');
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: { yul: false }
      }
    }
  },
  defaultNetwork: 'hardhat',
  networks: {
    bsc: {
        url: "https://rpc.ankr.com/polygon/e055afb958402bd2a97b039ae8452bb10b880d67994b18a3383ef4c34cf05b49",
        chainId: 137,
        gasPrice: 20000000000,
        accounts: {mnemonic: process.env.MNEMONIC},
        verify: {
          etherscan: {
            apiKey: process.env.ETHERSCAN_API_BSC
          }
        }
    },
    polygon: {
      url: "https://rpc.ankr.com/polygon/e055afb958402bd2a97b039ae8452bb10b880d67994b18a3383ef4c34cf05b49",
      chainId: 137,
      gasPrice: 110000000000,
      accounts: {mnemonic: process.env.MNEMONIC},
      verify: {
        etherscan: {
          apiKey: process.env.ETHERSCAN_API_POLYGON
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
      hardhat: {
        chainId: 31337,
        accounts: {mnemonic: process.env.MNEMONIC},
        forking: {
            url: 'https://rpc.ankr.com/polygon/e055afb958402bd2a97b039ae8452bb10b880d67994b18a3383ef4c34cf05b49'
        }
      },
      localhost: {
        accounts: {mnemonic: process.env.MNEMONIC}
      }
    },
  etherscan: {
    apiKey:process.env.ETHERSCAN_API_POLYGON
  },
  namedAccounts : {
    deployer: {
        default: 0
    }
  },
  gasReporter: {
    enabled: true
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: false,
    only: [],
    except: []
  },
  tenderly: {
    project: "project",
    username: "CryptoCult"
  }
};

