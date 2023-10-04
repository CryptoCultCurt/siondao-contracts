const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
const hre = require("hardhat");
let { POLYGON } = require('../../utils/assets');

module.exports = async () => {

    const vault = await ethers.getContract("RewardsVault");
    const sion = await ethers.getContract("Sion");
    const sionVault = await ethers.getContract("SionVault");

    console.log('setting underlying asset');
    await vault.setUnderlyingAsset(sion.address);
    console.log('underlying asset set to: ', sion.address);
    await rewardsVault.connect(signer).setVault(sionVault.address);

};

module.exports.tags = ['vesionsetting', 'SettingRewardsVault'];
