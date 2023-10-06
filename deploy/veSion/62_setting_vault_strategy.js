const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
const hre = require("hardhat");
let { POLYGON } = require('../../utils/assets');

module.exports = async () => {

  const vault = await ethers.getContract("SionVault");
  const strategy = await ethers.getContract("SionVaultStrategy");
  const ul = await ethers.getContract("UniversalLiquidator");
  const ulr = await ethers.getContract("UniversalLiquidatorRegistry");
  const vaultManager = await ethers.getContract("SionVaultManager");
  const sionToken = await ethers.getContract("Sion");
  const dex = "0xBC00945395d2aE7Eddced6AaB9A6733997efa0ab"; //CURRENTLY NON-PROXY await ethers.getContract("PearlDex");
  const wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
  

  let usdc = POLYGON.usdc;
  let cvr = POLYGON.cvr;
  let weth = POLYGON.weth;
  let usdr = POLYGON.usdr;
  let pearl = POLYGON.pearl;
  let sion = sionToken.address;

  await strategy.setUniversalLiquidator(ul.address);
  // add the reward tokens
  await strategy.addRewards([sion,usdc,usdr]);

 
};

module.exports.tags = ['vesionsetting', 'SettingVault'];
