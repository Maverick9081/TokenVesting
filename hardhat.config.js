require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");
require("./scripts/deploy.js");

const { ALCHEMY_KEY, ACCOUNT_PRIVATE_KEY,ETHERSCAN_API_KEY} = process.env;

module.exports = {
  solidity: "0.8.4",
  defaultNetwork : "rinkeby",
  networks : {
    rinkeby : {
      url : `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_KEY}`,
      accounts : [`0x${ACCOUNT_PRIVATE_KEY}`]
    }
  },
  etherscan : {
    apiKey: ETHERSCAN_API_KEY,
  }
};