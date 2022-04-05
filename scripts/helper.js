const { ethers } = require("ethers");


function getEnvVariable(key,defaultValue) {
    if(process.env[key]) {
        return process.env[key];
    }

    if(!defaultValue) {
        throw `${key} is not envirnoment variable`
    }
    return defaultValue;
}

function getProvider() {
    return ethers.getDefaultProvider(getEnvVariable("NETWORK","rinkeby"), {
        alchemy : getEnvVariable("ALCHEMY_KEY"),
    });
}

function getAccount() {
    return new ethers.Wallet(getEnvVariable("ACCOUNT_PRIVATE_KEY"),getProvider());
}

module.exports = {
    getEnvVariable,
    getProvider,
    getAccount
}