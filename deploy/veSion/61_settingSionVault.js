const { ethers } = require("hardhat");
const constants = require('../../utils/constants');

module.exports = async () => {
  const vault = await ethers.getContract("SionVault");
  const vaultManager = await ethers.getContract("SionVaultManager");
  const m2m = await ethers.getContract("SionVaultM2M");

  const sionToken = await ethers.getContract("Sion");
  const sion = sionToken.address;

  // setup metavault
  await vault.setVaultManager(vaultManager.address);
  await vault.setMark2Market(m2m.address);

  // setup vault manager
  await vaultManager.setAsset(sion);

  // setup m2m
  await (await m2m.setVaultManager(vaultManager.address)).wait();
  console.log("SION VAULT SETTINGS done");
};

module.exports.tags = ['vesionsetting', 'SettingVault'];
