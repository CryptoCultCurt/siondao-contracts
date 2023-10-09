const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
const hre = require("hardhat");
let { POLYGON } = require('../../utils/assets');

module.exports = async () => {

    const rewardsVault = await ethers.getContract("RewardsVault");
    const sion = await ethers.getContract("Sion");
    const sionVault = await ethers.getContract("SionVault");
    const ul = await ethers.getContract("UniversalLiquidator");
    const ulr = await ethers.getContract("UniversalLiquidatorRegistry");
    const dex = await ethers.getContract("PearlDex");

    let usdc = POLYGON.usdc;
    let cvr = POLYGON.cvr;
    let weth = POLYGON.weth;
    let usdr = POLYGON.usdr;
    let pearl = POLYGON.pearl;

    console.log('setting underlying asset');
    await rewardsVault.setUnderlyingAsset(sion.address);
    console.log('underlying asset set to: ', sion.address);
  //  await rewardsVault.setVault(sionVault.address);

  // setup universal liquidator
  console.log('setting path registry');
    await ul.setPathRegistry(ulr.address);
  console.log('path registry set to: ', ulr.address);

  // setup universal liquidator registry
  console.log('setup dex');
    // get the dex
  let dexes =await ulr.getAllDexes();
  if (!dexes.length || dexes.length == 0) {
    const name = ethers.utils.formatBytes32String('PearlDex');
    await ulr.addDex(name, dex.address);
    console.log('dex added')
    console.log('setting paths');
    dexes = await ulr.getAllDexes();
    await ulr.setPath(dexes[0], [usdr, pearl, weth]);
    await ulr.setPath(dexes[0], [weth, pearl, usdr]);
    await ulr.setPath(dexes[0], [cvr, pearl, usdr]);
    await ulr.setPath(dexes[0], [usdr, pearl, cvr]);
    await ulr.setPath(dexes[0], [usdc, usdr, pearl, cvr]); // new
    await dex.pairSetup(POLYGON.usdc, POLYGON.usdr,true);
    await dex.pairSetup(POLYGON.usdr, POLYGON.usdc,true);
    console.log('paths set');
  } else {
    console.log('dex already added at address: ', dexes[0]);
  }

};

module.exports.tags = ['vesionsetting', 'SettingRewardsVault'];
