const { ethers } = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const m2m = await ethers.getContract("Mark2MarketVaults");
    const vm = await ethers.getContract("SionVaultManager");
    await (await m2m.setVaultManager(vm.address)).wait();
    console.log("m2m.setVaultManager done");
};

module.exports.tags = ['vesionsetting','SettingSionM2M'];
