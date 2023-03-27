
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");
const wmxLPABI = require('../utils/abi/wmxLp.json');
const poolAbi = require('../utils/abi/ThenaPool.json');
const gaugeAbi = require('../utils/abi/ThenaGauge.json');
const axios = require('axios');

async function main() {

    let ethers = hre.ethers;
    const pm = await constants.getContract('PortfolioManager');
    let theToken = await axios.get('https://api.crypto-api.com/api/token/the');
    let wombatRewardsValue = 0;
    /// MANUALLY ADDED

    // wombat
    const wmx = await constants.getContract("StrategyWombexBusd");
    let wmxLpToken = await wmx.wmxLpBusd();
    const wmxContract = await ethers.getContractAt(wmxLPABI, wmxLpToken);
    let rewards = await wmxContract.claimableRewards(wmx.address);
    let i =0;
    for (reward of rewards[0]) {
        let token = await axios.get(`https://api.crypto-api.com/api/token/contract/${rewards[0][i]}/bsc`);
        wombatRewardsValue += token.data.usdPrice*rewards[1][i];
        i++;
    }

    // thena
    const usdPlus = await constants.getContract("StrategyThenaUsdtUsdPlus");
    let thenaPool = await ethers.getContractAt(poolAbi, await usdPlus.pair());
    let thenaGauge = await ethers.getContractAt(gaugeAbi, await usdPlus.gauge());
    let usdPlusRewards = await thenaGauge.earned(usdPlus.address);
    let usdPlusRewardsValue = usdPlusRewards*theToken.data.usdPrice;


    // thena
    const wUsdr = await constants.getContract("StrategyThenawUsdrUsdc");
    thenaPool = await ethers.getContractAt(poolAbi, await wUsdr.pair());
    thenaGauge = await ethers.getContractAt(gaugeAbi, await wUsdr.gauge());
    let wUsdrRewards = await thenaGauge.earned(wUsdr.address);
    let wUsdrRewardsValue = wUsdrRewards*theToken.data.usdPrice;
    const totalRewards = wombatRewardsValue+usdPlusRewardsValue+wUsdrRewardsValue;

    const token = await constants.getContract('SionToken');
    let totalMint = await token.totalMint();
   
    console.log(`Rewards:
    Wombat:     ${ethers.utils.formatEther(wombatRewardsValue)}
  

    Minted:     ${ethers.utils.formatEther(totalMint)}  
    `)

    const ownerLength = await token.ownerLength();

    for (let i=0;i<ownerLength;i++) {
        let owner = await token.ownerAt(i);
        let balance = await token.ownerBalanceAt(i)
        let percentage = balance/totalMint;
        let totalShare = totalRewards.toString()*percentage;
        console.log(`Owner#${i}:
        Owner:       ${owner}
        Balance:     ${ethers.utils.formatEther(balance)}
        New Tokens:  ${totalShare/1000000000000000000}
        `)
    }
    
}

main();