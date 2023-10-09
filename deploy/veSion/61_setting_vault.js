const { ethers } = require("hardhat");
const constants = require('../../utils/constants');
const hre = require("hardhat");
let { POLYGON } = require('../../utils/assets');


module.exports = async () => {

  const vault = await ethers.getContract("SionVault");
  const strategy = await ethers.getContract("CaviarVaultStrategy");
  const ul = await ethers.getContract("UniversalLiquidator");
  const ulr = await ethers.getContract("UniversalLiquidatorRegistry");
  const sionToken = await ethers.getContract("Sion");
  const vaultManager = await ethers.getContract("SionVaultManager");
  const m2m = await ethers.getContract("Mark2MarketVaults");
  const dex = await ethers.getContract("PearlDex");
  const wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
  

  let usdc = POLYGON.usdc;
  let cvr = POLYGON.cvr;
  let weth = POLYGON.weth;
  let usdr = POLYGON.usdr;
  let pearl = POLYGON.pearl;
  let sion = sionToken.address;


  // setup vault
  console.log('setting strategy');
  //await vault.setStrategy(strategy.address);
  console.log('strategy set to: ', strategy.address);
  console.log('setting vault fraction to invest')
  //await vault.setVaultFractionToInvest(90,100); // leaves 10% in vault
  console.log('vault fraction to invest set.');
  console.log('setting underlying asset');
 // await vault.setUnderlyingAsset(sion);
  console.log('underlying asset set to: ', sion);
  await vault.setVaultManager(vaultManager.address);
  console.log('vault manager set');

  // setup strategy
  console.log('setting vault address');
   await strategy.setVault(vault.address);
  console.log('vault address set to: ', vault.address);
  console.log('setting iFarm address');
   await strategy.setIFarm(usdr);
  console.log('iFarm address set to: ', ul.address);
  console.log('setting reward token');
   await strategy.setRewardToken(usdc);
  console.log('reward token set to: ', usdc);
  console.log('setting strategist');
   await strategy.setStrategist(wallet);
  console.log('strategist set to: ', wallet);
  console.log('set governance');
    await strategy.setGovernance(wallet);
  console.log('governance set to: ', wallet);
  console.log('setting protocol fee receiver');
   await strategy.setProtocolFeeReceiver(wallet);
  console.log('protocol fee receiver set to: ', wallet);
  console.log('setting profit sharing receiver');
    await strategy.setProfitSharingReceiver(wallet);
  console.log('profit sharing receiver set to: ', wallet);
  console.log('setting universal liquidator');
   await strategy.setUniversalLiquidator(ul.address);
  console.log('universal liquidator set to: ', ul.address);
  console.log('setting profit sharing numerator');
 //  await strategy.setProfitSharingNumerator(800); //8%
  console.log('profit sharing numerator set to: 8%');
  console.log('setting platform fee numerator');
 // await strategy.setPlatformFeeNumerator(1);
  console.log('platform fee numerator set to: 1');
  console.log('setting strategist fee numerator');
 //  await strategy.setStrategistFeeNumerator(1);
  console.log('strategist fee numerator set to: 1');
  await vault.setMark2Market(m2m.address);

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

module.exports.tags = ['vesionsetting', 'SettingVault'];
