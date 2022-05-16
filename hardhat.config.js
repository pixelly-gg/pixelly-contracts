require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomiclabs/hardhat-solhint");
require("hardhat-contract-sizer");
require("@openzeppelin/hardhat-upgrades");

const PRIVATE_KEY = process.env.PRIVATE_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: false,
  },
  networks: {
    mainnet: {
      url: `https://evm-cronos.crypto.org`,
      chainId: 25,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    testnet: {
      url: `https://matic-mumbai.chainstacklabs.com`,
      chainId: 80001,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/9272c529b110464abab493da913448a2`,
      chainId: 4,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    coverage: {
      url: "http://localhost:8555",
    },

    localhost: {
      url: `http://127.0.0.1:8545`,
    },
  },
  etherscan: {
    apiKey: "46DD6NK19R2AZQQIJIY1FXR85HKM2XSNBE",
  },
};
