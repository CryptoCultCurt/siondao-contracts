const {ethers} = require("hardhat");

let {DEFAULT, BSC, OPTIMISM, ARBITRUM} = require('../utils/assets');
const hre = require("hardhat");

module.exports = async () => {

    const pm = await ethers.getContract("PortfolioManager");
    const exchange = await ethers.getContract("Exchange");
    const m2m = await ethers.getContract("Mark2Market");

    let asset;
    if (hre.network.name === 'bsc') {
        asset = BSC.usdt;
    } else if (hre.network.name === "bsc_usdc") {
        asset = BSC.usdc;
    } else if (hre.network.name === "bsc_usdt") {
        asset = BSC.usdt;
    } else if (hre.network.name === "testnet") {
        asset = "0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee";
    }
    else {
        asset = POLYGON.usdc;
    }

    await (await pm.setMark2Market(m2m.address)).wait();
    console.log("pm.setMark2Market done");

    await (await pm.setExchanger(exchange.address)).wait();
    console.log("pm.setExchanger done");

    await (await pm.setAsset(asset)).wait();
    console.log(`pm.setAsset done ${asset}`);

};

module.exports.tags = ['sionsetting', 'SettingPM'];

