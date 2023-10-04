

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
    let wallet2 = '0x10444014ba4831fa355bc57b2d30a383baa11285';
    const [owner, deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    let rewardsVault = await constants.getContract('RewardsVault', 'localhost');
    let strategy = await constants.getContract('CaviarStrategy', 'localhost');
    let sionVault = await constants.getContract('SionVault', 'localhost');
    console.log(`Address:     ${rewardsVault.address}`);

    // setup
    const CVR = "0x6AE96Cc93331c19148541D4D2f31363684917092";
    // const strategy = "0xE8d84555Bb2D1C715467290F5D2759c3768f0b2d";
    const signer = await ethers.getSigner(wallet);
    const signer2 = await ethers.getSigner(wallet2);
    const caviar = await getERC20ByAddress(CVR, signer);
    const usdr = await getERC20ByAddress(POLYGON.usdr, signer);
    const sion = await constants.getContract('Sion');
    const usdc = await getERC20ByAddress(POLYGON.usdc, signer);

    async function setup() {
        await rewardsVault.connect(signer).setVault(sionVault.address);
    }

    async function stake(_amount, walleta, walletb) {
        // const previewDeposit = await rewardsVault.previewDeposit(ethers.utils.parseEther("1.0"));
        // console.log(`Preview Deposit: ${previewDeposit}`);
        await sion.connect(signer).approve(rewardsVault.address, ethers.utils.parseEther("999999999999999999999999.0"));
        await sion.connect(signer2).approve(rewardsVault.address, ethers.utils.parseEther("999999999999999999999999.0"));
        console.log('stake contract approved');
        if (walleta)
            await rewardsVault.connect(signer).stake(_amount.toString());
        if (walletb)
            await rewardsVault.connect(signer2).stake(_amount.toString());
    }

    async function addRewards(_amount) {
        // const previewDeposit = await rewardsVault.previewDeposit(ethers.utils.parseEther("1.0"));
        // console.log(`Preview Deposit: ${previewDeposit}`);
        await sion.connect(signer).approve(rewardsVault.address, ethers.utils.parseEther("999999999999999999999999.0"));
        //await wallet.connect(signer).transfer(usdr.connect(signer).donate(usdr.address, _amount.toString());
        await sion.transfer(
            rewardsVault.address,
            _amount
        )
        await rewardsVault.notifyRewardAmount(_amount.toString());
    }

    async function rebalance() {
        await rewardsVault.connect(signer).rebalance();
    }

    async function mine(blocks) {
        //await ethers.provider.send("evm_mine", new Date().getTime() + 1000);
        await helpers.mine(blocks, { interval: 2 })
        //  await helpers.time.increase(3600);
    }

    async function withdraw(_amount) {
        const previewWithdraw = await rewardsVault.previewWithdraw(_amount.toString());
        console.log(`Preview Withdraw: ${previewWithdraw}`);
        // const assets = await rewardsVault.connect(signer).withdraw(10000000000000,wallet,wallet);
        await rewardsVault.connect(signer).withdrawShares(_amount.toString());

        // console.log(`Withdraw: ${withdraw}`);
    }

    async function claim() {
        await rewardsVault.connect(signer).claim();
        await rewardsVault.connect(signer2).claim();
    }

    async function doHardWork() {
        await rewardsVault.connect(signer).doHardWork();
    }


    //await addRewards('10000000000000000000000');
    // await stake('1000000000000000000',true,false);
    //await setup();
    await mine(3600); // 86400 seconds in a day, blocks are 2 seconds apart so 43200 blocks in a day or 1800 blocks in an hour
    //   await claim();

    const asset = await rewardsVault.asset();
    const decimals = await rewardsVault.decimals();
    const name = await rewardsVault.name();
    const underlyingAddress = await rewardsVault.underlying();
    const _underlyingUnit = await rewardsVault.underlyingUnit();
    const strategyBalance = await caviar.balanceOf(strategy.address);
    const underlyingBalance = await caviar.balanceOf(rewardsVault.address);
    const walletBalance = await caviar.balanceOf(wallet);
    const walletUSDR = await usdr.balanceOf(wallet);
    const walletUSDR1285 = await usdr.balanceOf(wallet2);
    const walletSion = await sion.balanceOf(wallet);
    const walletSion1285 = await sion.balanceOf(wallet2);
    const walletUSDC = await usdc.balanceOf(wallet);
    const walletUSDC1285 = await usdc.balanceOf(wallet2);
    const rewardsInVault = await sion.balanceOf(rewardsVault.address);

    // new stuff
    const userRewardPerTokenPaid = await rewardsVault.userRewardPerTokenPaid(wallet);
    const userRewardPerTokenPaid1285 = await rewardsVault.userRewardPerTokenPaid(wallet2);
    const rewardPerToken = await rewardsVault.rewardPerToken();

    const periodFinish = await rewardsVault.periodFinish();
    const currentTime = new Date().getTime() / 1000;

    const rewardRate = await rewardsVault.rewardRate();
    const lastUpdateTime = await rewardsVault.lastUpdateTime();
    const rewards = await rewardsVault.rewards(wallet);
    const rewards1285 = await rewardsVault.rewards(wallet2);
    const totalSupply = await rewardsVault.totalSupply();
    const balanceOfStrat = await rewardsVault.balanceOf(wallet);
    const balanceOfStrat1285 = await rewardsVault.balanceOf(wallet2);
    const earned = await rewardsVault.earned(wallet);
    const earned1285 = await rewardsVault.earned(wallet2);




    console.log(`rewardsVault Settings:
name:                                           ${name}
decimals:                                       ${decimals}
asset:                                          ${asset}
SION LOCKED (totalSupply):                      ${constants.toDec18(totalSupply, 18)}
rewards in rewardsVault:                               ${constants.toDec18(rewardsInVault, 18)}
_underlyingUnit:                                ${constants.toDec18(_underlyingUnit, 18)}
_underlying:                                    ${underlyingAddress}

usdr stuck in strategy                          ${constants.toDec18(strategyBalance, 9)}
usdr in rewardsVault                            ${constants.toDec18(underlyingBalance, 9)}
wallet (3341) caviar                            ${constants.toDec18(walletBalance)}
wallet (3341) usdr                              ${constants.toDec18(walletUSDR, 9)}
wallet (3341) sion                              ${constants.toDec18(walletSion, 18)}
wallet (3341) usdc                              ${constants.toDec18(walletUSDC, 9)}

wallet (1285) usdr                              ${constants.toDec18(walletUSDR1285, 9)}
wallet (1285) sion                              ${constants.toDec18(walletSion1285, 18)}
wallet (1285) usdc                              ${constants.toDec18(walletUSDC1285, 9)}

periodFinish:                                   ${periodFinish}
currentTime:                                    ${currentTime}
lastUpdateTime:                                 ${lastUpdateTime}


rewards (3341):                                 ${constants.toDec18(rewards, 9)}
rewards (1285):                                 ${constants.toDec18(rewards1285, 9)}
rewards earned (3341)                           ${constants.toDec18(earned, 9)}  
rewards earned (1285)                           ${constants.toDec18(earned1285, 9)}
balanceOfStrat (3341):                          ${constants.toDec18(balanceOfStrat, 9)}
balanceOfStrat (1285):                          ${constants.toDec18(balanceOfStrat1285, 9)}

userRewardPerTokenPaid (3341):                  ${constants.toDec18(userRewardPerTokenPaid, 9)} 
userRewardPerTokenPaid (1285):                  ${constants.toDec18(userRewardPerTokenPaid1285, 9)}
rewardPerToken:                                 ${constants.toDec18(rewardPerToken, 9)}
rewardRate:                                     ${constants.toDec18(rewardRate, 9)}


    `);



}

main();