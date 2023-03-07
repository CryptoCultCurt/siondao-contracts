const {ethers} = require("hardhat");

const hre = require("hardhat");
let {DEFAULT, BSC, OPTIMISM, COMMON, ARBITRUM} = require('../utils/assets');

module.exports = async () => {

    const exchange = await ethers.getContract("Exchange");
    const token = await ethers.getContract("TestToken");
    const m2m = await ethers.getContract("Mark2Market");
    const pm = await ethers.getContract("PortfolioManager");

    let asset = BSC.busd;

    console.log("exchange.setToken: token " + token.address + " asset: " + asset);
    let tx = await exchange.setTokens(token.address, asset);
    await tx.wait();
    console.log("exchange.setTokens done");

    // setup exchange
    console.log("exchange.setPortfolioManager: " + pm.address);
    tx = await exchange.setPortfolioManager(pm.address);
    await tx.wait();
    console.log("exchange.setPortfolioManager done");

    console.log("exchange.setMark2Market: " + m2m.address);
    tx = await exchange.setMark2Market(m2m.address);
    await tx.wait();
    console.log("exchange.setMark2Market done");


};

module.exports.tags = ['setting', 'SettingExchange'];
