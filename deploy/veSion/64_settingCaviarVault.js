const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
let { POLYGON } = require('../../utils/assets');

module.exports = async () => {
  const vault = await ethers.getContract("CaviarVault");
  const vaultManager = await ethers.getContract("CaviarVaultManager");
  const m2m = await ethers.getContract("CaviarVaultM2M");

  const sionToken = await ethers.getContract("Sion");
  const sion = sionToken.address;

  const cvr = POLYGON.cvr;

  // setup metavault
  await vault.setVaultManager(vaultManager.address);
  await vault.setMark2Market(m2m.address);

  // setup vault manager
  await vaultManager.setAsset(cvr);

  // setup m2m
  await (await m2m.setVaultManager(vaultManager.address)).wait();
  console.log("CAVIAR VAULT SETTINGS done");
};

module.exports.tags = ['vesionsetting', 'SettingVault'];
