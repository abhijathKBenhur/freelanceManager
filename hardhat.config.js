/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");


const DEPLOYER_PRIVATE_KEY = "7e2417d1173d7f1e0d9c420c0cf56f17566b817d966fb80cd4f913d46c98d24c"

module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url:"https://eth-goerli.g.alchemy.com/v2/eUycF7fKBspwaBJnOPcDMPAU2nSoLIDQ",
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    }
  },
  gasReporter: {
    currency: 'INR',
    gasPrice: 21
  }
};
