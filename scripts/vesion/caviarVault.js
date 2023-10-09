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
  let sionVault = await constants.getContract('CaviarVault', 'localhost');
  let sionVaultStrategy = await constants.getContract('CaviarVaultStrategy', 'localhost');
  let sionVaultManager = await constants.getContract('CaviarVaultManager', 'localhost');
  let sionM2M = await constants.getContract('CaviarVaultM2M', 'localhost');

  //let strategy = await constants.getContract('CaviarVaultStrategy', 'localhost');
  let rewardsVault = await constants.getContract('RewardsVault', 'localhost');

  let sion = await constants.getContract('Sion');
  console.log(`Vault Address:             ${sionVault.address}`);
  console.log(`Rewards Vault Address:     ${rewardsVault.address}`);
  console.log(`SionVaultStrategy Address: ${sionVaultStrategy.address}`);
  console.log(`SionVaultManager Address:  ${sionVaultManager.address}`);
  console.log(`Mark2MarketVaults Address: ${sionM2M.address}`);


  // setup
  const CVR = "0x6AE96Cc93331c19148541D4D2f31363684917092";
  // const strategy = "0xE8d84555Bb2D1C715467290F5D2759c3768f0b2d";
  const signer = await ethers.getSigner(wallet);
  const caviar = await getERC20ByAddress(CVR, signer);
  const usdr = await getERC20ByAddress(POLYGON.usdr, signer);
  const usdc = await getERC20ByAddress(POLYGON.usdc, signer);

  async function setup() {
    console.log('setting m2m');
    await sionVault.setMark2Market(sionM2M.address);
    console.log('setting vault manager');
    await sionVault.setVaultManager(sionVaultManager.address);
  }

  async function purchase(_amount) {
    // const previewDeposit = await sionVault.previewDeposit(ethers.utils.parseEther("1.0"));
    // console.log(`Preview Deposit: ${previewDeposit}`);
    await caviar.connect(signer).approve(sionVault.address, ethers.utils.parseEther("999999999999999999999999.0"));
    await caviar.connect(signer).approve(sionVault.address, ethers.utils.parseEther("999999999999999999999999.0"));
    await caviar.connect(signer).approve(rewardsVault.address, ethers.utils.parseEther("999999999999999999999999.0"));

    const deposit = await sionVault.connect(signer).deposit(_amount.toString(), wallet);
  }

  async function rebalance() {
    await sionVault.connect(signer).rebalance();
  }

  async function mine(blocks) {
    //await ethers.provider.send("evm_mine", new Date().getTime() + 1000);
    await helpers.mine(blocks, { interval: 2 })
    //  await helpers.time.increase(3600);
  }

  async function withdraw(_amount) {
    if (_amount == 0) {
      console.log('withdrawing all');
      _amount = await sionVault.maxWithdraw(wallet);

    }
    const previewWithdraw = await sionVault.previewWithdraw(_amount.toString());
    console.log(`Preview Withdraw: ${previewWithdraw}`);
    // const assets = await sionVault.connect(signer).withdraw(10000000000000,wallet,wallet);
    await sionVault.connect(signer).withdrawShares(_amount.toString());

    // console.log(`Withdraw: ${withdraw}`);
  }

  async function doHardWork() {
    await sionVault.connect(signer).doHardWork();
  }

  //await purchase(1000);
  await mine(4000);


  const asset = await sionVault.asset();
  const decimals = await sionVault.decimals();
  const name = await sionVault.name();
  const sionVaultStrategyTokenName = await sionVaultStrategy.name();
  const underlyingBalanceWithInvestment = ''//await sionVault.underlyingBalanceWithInvestment();
  const pendingReward = 0//await strategy.pendingReward(); // pending rewards are wUSDR (not usdr), but harvest converts to usdr and gives rebase of caviar
  const vaultStategyBalance = await sion.balanceOf(sionVaultStrategy.address);

  const assetsOf = ''//await sionVault.assetsOf(wallet);
  // console.log(`Assets of ${wallet}: ${assetsOf}`);
  //  balanceOf = await sionVault.balanceOf(wallet);
  //  console.log(`Balance of ${wallet}: ${balanceOf}`);
  const assetsPerShare = ''//await sionVault.assetsPerShare();
 // const availableToInvestOut = await sionVault.availableToInvestOut();
 // const pricePerFullShare = await sionVault.getPricePerFullShare();
  // const totalAssets = await sionVault.totalAssets();
  // const totalSupply = await sionVault.totalSupply();
  // const underlyingBalanceInVault = await sionVault.underlyingBalanceInVault();
  //const assetsOfWallet = await sionVault.assetsOf(wallet);


  const underlyingBalance = await caviar.balanceOf(sionVault.address);
  const walletBalance = await caviar.balanceOf(wallet);
  const investedBalance = underlyingBalanceWithInvestment - underlyingBalance;
  const walletUSDR = await usdr.balanceOf(wallet);
  const walletSion = await sion.balanceOf(wallet);

  // new stuff
  //const userRewardPerTokenPaid = await strategy.userRewardPerTokenPaid(wallet);
  //const rewardPerToken = await strategy.rewardPerToken();

  //const periodFinish = await strategy.periodFinish();

  // const rewardRate = await strategy.rewardRate();
  // const lastUpdateTime = await strategy.lastUpdateTime();
  // const rewards = await strategy.rewards(wallet);
  // const totalSupplyStrat = await strategy.totalSupply();
  // const balanceOfStrat = await strategy.balanceOf(wallet);



  console.log(`
Vault Settings:
name:                                           ${name}
vault strategy name:                            ${sionVaultStrategyTokenName}
decimals:                                       ${decimals}
underlying asset:                               ${asset}

SION VAULT STATS
totalSupply:                                    NOT IMPLEMENTED
totalAssets:                                    NOT IMPLEMNETED
assetsPerShare:                                 ${constants.toDec18(assetsPerShare)}
pricePerFullShare:                              NOT IMPLEMENTED
underlyingBalanceInVault:                       NOT IMPLEMENTED
underlyingBalanceWithInvestment:                NOT IMPLEMENTED
availableToInvestOut:                           NOT IMPLEMENTED


caviar in sionVault                             ${constants.toDec18(underlyingBalance)}
caviar invested                                 ${constants.toDec18(investedBalance)}

SION VAULT STRATEGY STATS
Sion Balance                                    ${constants.toDec18(vaultStategyBalance)} 


WALLET STATS (3341)
assetsOf (3341):                                ${constants.toDec18(assetsOf)}
wallet caviar                                   ${constants.toDec18(walletBalance)}
wallet usdr                                     ${constants.toDec18(walletUSDR, 9)}
wallet sion                                     ${constants.toDec18(walletSion, 18)}

    `);



}

main();