const { ethers } = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const token = await ethers.getContract("Sion");
    const exchange = await ethers.getContract("Exchange");

    console.log('token.setExchanger: ' + exchange.address)
    let tx = await token.setExchanger(exchange.address);
    await tx.wait();
    console.log("token.setExchanger done");
};

module.exports.tags = ['sionsetting','SettingToken'];
