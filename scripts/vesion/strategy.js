

// asset()
// totalAssets()
// assetsPerShare()
// assetsOf(address _depositor)
// maxDeposit(address /*caller*/)

const {ethers} = require("hardhat");
const {getERC20} = require("../../utils/script-utils");
const {BSC} = require('../../utils/assets');
const constants = require('../../utils/constants');
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");


async function main() {
    let ethers = hre.ethers;
    let wallet = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
   // console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

   // const exchange = await constants.getContract('Exchange');
    let vault = await constants.getContract('CaviarStrategy','localhost');
    console.log(`Address:     ${vault.address}`);

    // setup
    const CVR = '0x6AE96Cc93331c19148541D4D2f31363684917092';

    async function withdrawAllToVault() {
        console.log('withdraw all to vault');
        await vault.withdrawAllToVault();
    }

    async function doHardWork() {
        console.log('do hard work');
        await vault.doHardWork();
    }

    async function setup() {
        //console.log('set vault address');
        //await vault.setVault("0xda98485C7C2A279c6d5Df1177042c286C7dEf206");
        // console.log('set iFarm address');
        // await vault.setIFarm("0x40379a439D4F6795B6fc9aa5687dB461677A2dBa"); // USDR
        // await vault.setRewardToken("0x6AE96Cc93331c19148541D4D2f31363684917092"); // CVR
        // await vault.setStrategist("0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341");
        // await vault.setProtocolFeeReceiver("0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341");
        // await vault.setProfitSharingReceiver("0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341");
        // await vault.setUniversalLiquidator("0xFe09cBAFAe91F144888D20Bb98c1849Ff2d05056");
        await vault.setProfitSharingNumerator(800); //8%
        // await vault.setPlatformFeeNumerator(1);
        // await vault.strategistFeeNumerator(1);
    }

    async function mine(blocks) {
        //await ethers.provider.send("evm_mine", new Date().getTime() + 1000);
          await helpers.mine(blocks, {interval: 2})
      }

  // await setup();
  // await doHardWork();
  await setup();
  await mine(41307);

   // const rewardTokens = await vault.rewardTokens();
    const rewardPool = await vault.rewardPool();
    const underlying = await vault.underlying();
    const rewardToken = await vault.rewardToken();
    const strategist = await vault.strategist();    
    const vaultAddr = await vault.vault();
    const universalLiquidator = await vault.universalLiquidator();
    const protocolFeeReceiver = await vault.protocolFeeReceiver();
    const profitSharingReceiver = await vault.profitSharingReceiver();
    const targetToken = await vault.targetToken();  
    const iFARM = await vault.iFARM();  
    const profitSharingNumerator = await vault.profitSharingNumerator();
    const platformFeeNumerator = await vault.platformFeeNumerator();
    const strategistFeeNumerator = await vault.strategistFeeNumerator();
    const feeDenominator = await vault.feeDenominator();
    const investedUnderlyingBalance = await vault.investedUnderlyingBalance();
    const rewardPoolBalance = await vault.rewardPoolBalance();
    const pendingReward = await vault.pendingReward();




    console.log(`Caviar Strategy Settings:

    rewardPool:                ${rewardPool}
    rewardPool Balance:        ${(rewardPoolBalance/1000000000000000000).toFixed(2)}
    pendingReward:             ${(pendingReward/1000000000000000000).toFixed(2)}    
    underlying:                ${underlying}
    rewardToken:               ${rewardToken}
    targetToken:               ${targetToken}
    iFARM:                     ${iFARM}
    vault:                     ${vaultAddr}
    universalLiquidator:       ${universalLiquidator}
    protocolFeeReceiver:       ${protocolFeeReceiver}
    profitSharingReceiver:     ${profitSharingReceiver}
    strategist:                ${strategist}
    profitSharingNumerator:    ${profitSharingNumerator}
    platformFeeNumerator:      ${platformFeeNumerator}
    strategistFeeNumerator:    ${strategistFeeNumerator}
    feeDenominator:            ${feeDenominator}

    investedUnderlyingBalance: ${(investedUnderlyingBalance/1000000000000000000).toFixed(2)}
    `);
   
   



}

main();