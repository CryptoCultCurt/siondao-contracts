

// asset()
// totalAssets()
// assetsPerShare()
// assetsOf(address _depositor)
// maxDeposit(address /*caller*/)

const { ethers } = require("hardhat");
const { getERC20, getERC20ByAddress } = require("../../utils/script-utils");
const { POLYGON } = require('../../utils/assets');
const constants = require('../../utils/constants');
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");


async function main() {
  // let ethers = hre.ethers;
  // hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
  // const provider = new ethers.providers.JsonRpcProvider(
  //     "http://localhost:8545"
  //   );
  let wallet = '0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341';
  const [owner, deployer] = await ethers.getSigners();
  const { chainId } = await ethers.provider.getNetwork();
  console.log(`\nOwner:       ${owner.address}`);
  // console.log(`Deployer:    ${deployer.address}`);
  console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
  console.log(`Chain:       ${chainId}`);

  // const exchange = await constants.getContract('Exchange');
  let vault = await constants.getContract('SionVault', 'localhost');
  let strategy = await constants.getContract('CaviarStrategy', 'localhost');
  let streamVault = await constants.getContract('RewardsVault', 'localhost');
  let sion = await constants.getContract('Sion');
  console.log(`Address:     ${vault.address}`);
  console.log('Rewards Vault: ', streamVault.address);

  // setup
  const CVR = "0x6AE96Cc93331c19148541D4D2f31363684917092";
  // const strategy = "0xE8d84555Bb2D1C715467290F5D2759c3768f0b2d";
  const signer = await ethers.getSigner(wallet);
  const caviar = await getERC20ByAddress(CVR, signer);
  const usdr = await getERC20ByAddress(POLYGON.usdr, signer);

  async function setup() {
    console.log('setting rewards vault');
    await vault.setRewardsVault(streamVault.address);
    //   console.log('setting strategy');
    //   await vault.setStrategy(strategy.address);
    //   console.log('strategy set to: ',strategy.address);
    //   console.log('setting vault fraction to invest')
    //   await vault.setVaultFractionToInvest(90,100);
    //   console.log('vault fraction to invest set to 1/100');
    //   console.log('setting underlying asset');
    //  await vault.setUnderlyingAsset(CVR);
    //   console.log('underlying asset set to: ',CVR);
  }

  async function purchase(_amount) {
    // const previewDeposit = await vault.previewDeposit(ethers.utils.parseEther("1.0"));
    // console.log(`Preview Deposit: ${previewDeposit}`);
    await caviar.connect(signer).approve(vault.address, ethers.utils.parseEther("999999999999999999999999.0"));
    await sion.connect(signer).approve(vault.address, ethers.utils.parseEther("999999999999999999999999.0"));
    await sion.connect(signer).approve(streamVault.address, ethers.utils.parseEther("999999999999999999999999.0"));

    const deposit = await vault.connect(signer).deposit(_amount.toString(), wallet);
  }

  async function rebalance() {
    await vault.connect(signer).rebalance();
  }

  async function mine(blocks) {
    //await ethers.provider.send("evm_mine", new Date().getTime() + 1000);
    await helpers.mine(blocks, { interval: 2 })
    //  await helpers.time.increase(3600);
  }

  async function withdraw(_amount) {
    if (_amount == 0) {
      console.log('withdrawing all');
      _amount = await vault.maxWithdraw(wallet);

    }
    const previewWithdraw = await vault.previewWithdraw(_amount.toString());
    console.log(`Preview Withdraw: ${previewWithdraw}`);
    // const assets = await vault.connect(signer).withdraw(10000000000000,wallet,wallet);
    await vault.connect(signer).withdrawShares(_amount.toString());

    // console.log(`Withdraw: ${withdraw}`);
  }

  async function doHardWork() {
    await vault.connect(signer).doHardWork();
  }
  // await setup();
  // await mine(410307); // one day
  // await mine(410307); // one day
  // await mine(410307); // one day
  // await setup();
  // await purchase('1'); // around $1000 usdc
  //await withdraw('500000000');
  // await rebalance();
  //await mine(410307);
  //await doHardWork();  // first calls _invest to move funds to strategy, then calls _harvest to harvest rewards
  //  await rebalance();
  await mine(4000);

  // await withdraw('993547044211312002653');
  // await vault.connect(signer).withdrawAll()
  //await vault.setUnderlyingAsset(CVR);
  //console.log('underlying asset set to: ',CVR);
  //await vault.connect(signer).sweepToVault();
  //await doHardWork();

  // **** FIX AND WITHDRAWS ****
  //  await vault.connect(signer).sweepToVault();
  // const maxRedeem = await vault.maxRedeem(wallet);
  // console.log('max redeem: %s ',maxRedeem.toString());
  //  //await vault.connect(signer).withdrawAll();
  // await withdraw(maxRedeem.toString());

  // await vault.connect(signer).invest();
  //await doHardWork();


  const asset = await vault.asset();
  const decimals = await vault.decimals();
  const name = await vault.name();
  const vaultFractionToInvestDenominator = await vault.vaultFractionToInvestDenominator();
  const vaultFractionToInvestNumerator = await vault.vaultFractionToInvestNumerator();
  const strategyAddress = await vault.strategy();
  const underlyingAddress = await vault.underlying();
  const _underlyingUnit = await vault.underlyingUnit();
  const underlyingBalanceWithInvestment = ''//await vault.underlyingBalanceWithInvestment();
  const pendingReward = 0//await strategy.pendingReward(); // pending rewards are wUSDR (not usdr), but harvest converts to usdr and gives rebase of caviar
  const rebaseChef = "0xf5374d452697d9A5fa2D97Ffd05155C853F6c1c6"; // caviar rebase chef

  const assetsOf = ''//await vault.assetsOf(wallet);
  // console.log(`Assets of ${wallet}: ${assetsOf}`);
  // balanceOf = await vault.balanceOf(wallet);
  // console.log(`Balance of ${wallet}: ${balanceOf}`);
  const assetsPerShare = ''//await vault.assetsPerShare();
  const availableToInvestOut = await vault.availableToInvestOut();
  const pricePerFullShare = await vault.getPricePerFullShare();
  const totalAssets = await vault.totalAssets();
  const totalSupply = await vault.totalSupply();
  const underlyingBalanceInVault = await vault.underlyingBalanceInVault();
  //const assetsOfWallet = await vault.assetsOf(wallet);

  const sellAllInUSD = constants.toDec18(await strategy.EstimateInUsd(totalAssets), 6);
  const pricePer = sellAllInUSD / constants.toDec18(totalAssets);


  const strategyBalance = await caviar.balanceOf(strategy.address);
  const underlyingBalance = await caviar.balanceOf(vault.address);
  const walletBalance = await caviar.balanceOf(wallet);
  const investedBalance = underlyingBalanceWithInvestment - underlyingBalance;
  const walletUSDR = await usdr.balanceOf(wallet);
  const walletSion = await sion.balanceOf(wallet);

  // new stuff
  const userRewardPerTokenPaid = await strategy.userRewardPerTokenPaid(wallet);
  const rewardPerToken = await strategy.rewardPerToken();

  const periodFinish = await strategy.periodFinish();

  const rewardRate = await strategy.rewardRate();
  const lastUpdateTime = await strategy.lastUpdateTime();
  const rewards = await strategy.rewards(wallet);
  const totalSupplyStrat = await strategy.totalSupply();
  const balanceOfStrat = await strategy.balanceOf(wallet);



  console.log(`Vault Settings:
name:                                           ${name}
decimals:                                       ${decimals}
asset:                                          ${asset}
pending rewards:                                ${pendingReward}
totalSupply:                                    ${constants.toDec18(totalSupply)}
totalAssets:                                    ${constants.toDec18(totalAssets)}
assetsPerShare:                                 ${constants.toDec18(assetsPerShare)}
pricePerFullShare:                              ${constants.toDec18(pricePerFullShare)}
underlyingBalanceInVault:                       ${constants.toDec18(underlyingBalanceInVault)}
underlyingBalanceWithInvestment:                ${constants.toDec18(underlyingBalanceWithInvestment)}
availableToInvestOut:                           ${constants.toDec18(availableToInvestOut)}
underlyingUnit:                                 ${constants.toDec18(_underlyingUnit)}
underlying token:                               ${underlyingAddress}
vaultFractionToInvestNumerator:                 ${vaultFractionToInvestNumerator}
vaultFractionToInvestDenominator:               ${vaultFractionToInvestDenominator}
strategy:                                       ${strategyAddress}

caviar stuck in strategy                        ${constants.toDec18(strategyBalance)}
caviar in vault                                 ${constants.toDec18(underlyingBalance)}
caviar invested                                 ${constants.toDec18(investedBalance)}

userRewardPerTokenPaid:                         ${constants.toDec18(userRewardPerTokenPaid)} 
rewardPerToken:                                 ${constants.toDec18(rewardPerToken)}
periodFinish:                                   ${periodFinish}
rewardRate:                                     ${constants.toDec18(rewardRate)}
lastUpdateTime:                                 ${lastUpdateTime}
rewards:                                        ${constants.toDec18(rewards)}
totalSupplyStrat:                               ${constants.toDec18(totalSupplyStrat)}
balanceOfStrat:                                 ${constants.toDec18(balanceOfStrat)}

WALLET STATS (3341)
porttfolio value:                               ${sellAllInUSD}
caviar value:                                   ${pricePer}
assetsOf (3341):                                ${constants.toDec18(assetsOf)}
wallet caviar                                   ${constants.toDec18(walletBalance)}
wallet usdr                                     ${constants.toDec18(walletUSDR, 9)}
wallet sion                                     ${constants.toDec18(walletSion, 18)}

    `);



}

main();