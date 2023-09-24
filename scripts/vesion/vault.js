

// asset()
// totalAssets()
// assetsPerShare()
// assetsOf(address _depositor)
// maxDeposit(address /*caller*/)

const {ethers} = require("hardhat");
const {getERC20,getERC20ByAddress} = require("../../utils/script-utils");
const {BSC} = require('../../utils/assets');
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
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
   // console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

   // const exchange = await constants.getContract('Exchange');
    let vault = await constants.getContract('VaultERC4626','localhost');
    let strategy = await constants.getContract('CaviarStrategy','localhost');
    console.log(`Address:     ${vault.address}`);

    // setup
    const CVR = "0x6AE96Cc93331c19148541D4D2f31363684917092";
   // const strategy = "0xE8d84555Bb2D1C715467290F5D2759c3768f0b2d";
    const signer = await ethers.getSigner(wallet);
    const caviar = await getERC20ByAddress(CVR,signer);

    async function setup() {
      console.log('setting strategy');
      await vault.setStrategy(strategy.address);
      console.log('strategy set to: ',strategy.address);
      console.log('setting vault fraction to invest')
      await vault.setVaultFractionToInvest(90,100);
      console.log('vault fraction to invest set to 1/100');
      console.log('setting underlying asset');
     await vault.setUnderlyingAsset(CVR);
      console.log('underlying asset set to: ',CVR);
    }  

    async function purchase(_amount) {
     // const previewDeposit = await vault.previewDeposit(ethers.utils.parseEther("1.0"));
     // console.log(`Preview Deposit: ${previewDeposit}`);
      await caviar.connect(signer).approve(vault.address,ethers.utils.parseEther("999999999999999999999999.0"));
      console.log('contract approved');
      const deposit = await vault.connect(signer).deposit(ethers.utils.parseEther(_amount.toString()),wallet);
    }

    async function rebalance() {
      await vault.connect(signer).rebalance();
    }

    async function mine(blocks) {
      //await ethers.provider.send("evm_mine", new Date().getTime() + 1000);
        await helpers.mine(blocks, {interval: 2})
    }

    async function withdraw(_amount) {
      const previewWithdraw = await vault.previewWithdraw(ethers.utils.parseEther(_amount.toString()));
      console.log(`Preview Withdraw: ${previewWithdraw}`);
     // const assets = await vault.connect(signer).withdraw(10000000000000,wallet,wallet);
  await vault.connect(signer).withdrawShares(ethers.utils.parseEther(_amount.toString()));
     
     // console.log(`Withdraw: ${withdraw}`);
    }

    async function doHardWork() {
      await vault.connect(signer).doHardWork();
    }
   // await setup();
  // await mine(410307); // one day
  // await mine(410307); // one day
  // await mine(410307); // one day
  // await purchase(4000); // around $1000 usdc
  // await rebalance();
  //await mine(410307);
  await doHardWork();  // first calls _invest to move funds to strategy, then calls _harvest to harvest rewards
//  await rebalance();
 //  await withdraw(1000);
 //await vault.setUnderlyingAsset(CVR);
 //console.log('underlying asset set to: ',CVR);
  //await doHardWork();
    
    const asset = await vault.asset();
    const decimals = await vault.decimals();
    const name = await vault.name();
    const vaultFractionToInvestDenominator = await vault.vaultFractionToInvestDenominator();
    const vaultFractionToInvestNumerator = await vault.vaultFractionToInvestNumerator();
    const strategyAddress = await vault.strategy();
    const underlyingAddress = await vault.underlying();
    const _underlyingUnit = await vault.underlyingUnit();
    const underlyingBalanceWithInvestment = await vault.underlyingBalanceWithInvestment();
const pendingReward = 0//await strategy.pendingReward(); // pending rewards are wUSDR (not usdr), but harvest converts to usdr and gives rebase of caviar
  
    const rebaseChef = "0xf5374d452697d9A5fa2D97Ffd05155C853F6c1c6"; // caviar rebase chef
 
    assetsOf = await vault.assetsOf(wallet);
    console.log(`Assets of ${wallet}: ${assetsOf}`);
    balanceOf = await vault.balanceOf(wallet);
    console.log(`Balance of ${wallet}: ${balanceOf}`);
    const assetsPerShare = await vault.assetsPerShare();
    const availableToInvestOut = await vault.availableToInvestOut();
    const pricePerFullShare = await vault.getPricePerFullShare();
    const totalAssets = await vault.totalAssets();
    const totalSupply = await vault.totalSupply();
    const underlyingBalanceInVault = await vault.underlyingBalanceInVault();
    const assetsOfWallet = await vault.assetsOf(wallet);

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
_underlyingUnit:                                ${constants.toDec18(_underlyingUnit)}
_underlying:                                    ${underlyingAddress}
_vaultFractionToInvestNumerator:                ${vaultFractionToInvestNumerator}
_vaultFractionToInvestDenominator:              ${vaultFractionToInvestDenominator}
_strategy:                                      ${strategyAddress}

    `);



}

main();