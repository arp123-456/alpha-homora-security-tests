require('@nomicfoundation/hardhat-toolbox');
require('@tenderly/hardhat-tenderly');
require('dotenv').config();

const { MAINNET_RPC_URL, MAINNET_FORK_BLOCK, TENDERLY_FORK_RPC, PRIVATE_KEY_DEPLOYER } = process.env;

module.exports = {
    solidity: {
        version: '0.8.20',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            },
            viaIR: true
        }
    },
    networks: {
        hardhat: {
            forking: {
                url: MAINNET_RPC_URL || 'https://eth-mainnet.g.alchemy.com/v2/demo',
                enabled: true,
                blockNumber: parseInt(MAINNET_FORK_BLOCK) || 18500000
            },
            chainId: 1,
            accounts: {
                count: 20,
                accountsBalance: '10000000000000000000000' // 10000 ETH
            }
        },
        tenderly: {
            url: TENDERLY_FORK_RPC || 'http://localhost:8545',
            chainId: 1,
            accounts: PRIVATE_KEY_DEPLOYER ? [PRIVATE_KEY_DEPLOYER] : []
        },
        mainnet: {
            url: MAINNET_RPC_URL || '',
            accounts: PRIVATE_KEY_DEPLOYER ? [PRIVATE_KEY_DEPLOYER] : [],
            chainId: 1
        }
    },
    tenderly: {
        project: process.env.TENDERLY_PROJECT || '',
        username: process.env.TENDERLY_USER || '',
        privateVerification: false,
        deploymentsDir: 'deployments'
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        showTimeSpent: true
    },
    mocha: {
        timeout: 200000
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
};