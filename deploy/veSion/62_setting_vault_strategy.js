const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
const hre = require("hardhat");
let { POLYGON } = require('../../utils/assets');

module.exports = async () => {

  const strategy = await ethers.getContract("SionVaultStrategy");
  const ul = await ethers.getContract("UniversalLiquidator");
  const sionToken = await ethers.getContract("Sion");
  const caviarVault = await ethers.getContract("CaviarVault");
  const sionExchange = await ethers.getContract("Exchange");

  let usdc = POLYGON.usdc;
  let usdr = POLYGON.usdr;
  let cvr = POLYGON.cvr;
  let sion = sionToken.address;

  await strategy.setUniversalLiquidator(ul.address);
  // add the reward tokens
 //await strategy.addRewards([sion,usdc,usdr]);  UNSURE IF THIS IS NEEDED
  await strategy.setUSDC(usdc);
  await strategy.setExchange(sionExchange.address);
  await strategy.setVault(caviarVault.address);
  await strategy.setCVRToken(cvr);


 
};

module.exports.tags = ['vesionsetting', 'SettingVaultStrategy'];
