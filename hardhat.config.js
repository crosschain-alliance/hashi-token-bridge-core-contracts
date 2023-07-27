require('dotenv').config()
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-etherscan')
require('hardhat-gas-reporter')
require('@nomicfoundation/hardhat-chai-matchers')
//require('hardhat-spdx-license-identifier')
require('hardhat-log-remover')
require('solidity-coverage')
require('@nomicfoundation/hardhat-toolbox')
require('hardhat-spdx-license-identifier')

require('./tasks')

const getEnvironmentVariable = (_envVar) => process.env[_envVar] || ''

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.19',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true
        }
      }
    }
  },
  networks: {
    hardhat: {},
    gnosis: {
      url: getEnvironmentVariable('GNOSIS_CHAIN_NODE'),
      accounts: [getEnvironmentVariable('PK')],
      gasPrice: 1.6e9
    },
    polygon: {
      url: getEnvironmentVariable('POLYGON_NODE'),
      accounts: [getEnvironmentVariable('PK')],
      gasPrice: 100e9
    },
    goerli: {
      url: getEnvironmentVariable('GOERLI_NODE'),
      accounts: [getEnvironmentVariable('PK')],
      gasPrice: 3.2e9
    }
  },
  gasReporter: {
    enabled: true
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: false
  },
  mocha: {
    timeout: 100000000
  },
  etherscan: {
    apiKey: {
      gnosis: process.env.GNOSISSCAN_API_KEY || '',
      polygon: process.env.POLYGONSCAN_API_KEY || ''
    }
  }
}
