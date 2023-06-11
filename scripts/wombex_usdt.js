
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");
const wmxLPABI = require('../utils/abi/wmxLp.json');
const axios = require('axios');

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const venusstrat = await constants.getContract("StrategyWombexUsdt");
    const exchange = await constants.getContract('Exchange');
    const pm = await constants.getContract('PortfolioManager');

    let usdtToken = await venusstrat.usdt();
    let busdToken = await venusstrat.busd();
    let lpUsdtToken = await venusstrat.lpUsdt();
    let poolDepositor = await venusstrat.poolDepositor();
    let  wombatRouter =  await venusstrat.wombatRouter();
    let womToken = await venusstrat.wom();
    let wmxLpToken = await venusstrat.wmxLpUsdt();
    let wmx = await venusstrat.wmx();


    const portfolioManager = await venusstrat.portfolioManager();
    const PORTFOLIO_MANAGER = await venusstrat.PORTFOLIO_MANAGER();
    const pmRole = await venusstrat.hasRole(PORTFOLIO_MANAGER,portfolioManager);


    console.log(`\nVenusBUSD Strategy:
    USDT:           ${usdtToken}
    BUSD:           ${busdToken}        
    lpUsdtToken:    ${lpUsdtToken}
    poolDepositor:  ${poolDepositor}
    wombatRouter:   ${wombatRouter}
    womToken:       ${womToken}
    wmxLpToken:     ${wmxLpToken}
    PM:             ${portfolioManager} (${pmRole})
    `)

    const wmxContract = await ethers.getContractAt(wmxLPABI, wmxLpToken);
    //const busd = await util.getERC20ByAddress(util.busd, venusstrat.address);
    const usdt = await util.getERC20ByAddress(usdtToken, venusstrat.address);
    const usdPlus = await util.getERC20ByAddress("0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65", venusstrat.address);
    const balance =     await wmxContract.balanceOf(venusstrat.address);
    const balanceBusd =0// await busd.balanceOf(exchange.address);
    const balanceUsdt = await usdt.balanceOf(exchange.address);
    const nav =  await venusstrat.netAssetValue();

    let rewards = await wmxContract.claimableRewards(venusstrat.address);

    let i=0;
    console.log(`Balances:
    wmx:                    ${balance}
    BUSD:                   ${balanceBusd}
    USDT:                   ${balanceUsdt}
    Net Asset Value:        ${nav}
    USDT Portfolio Manager: ${await usdt.balanceOf(pm.address)}
    USD+ PM:                ${await usdPlus.balanceOf(pm.address)}
    Rewards:                `)
    for (reward of rewards[0]) {
        let token = await axios.get(`https://api.crypto-api.com/api/token/contract/${rewards[0][i]}/bsc`);
        console.log(`       Token: ${token.data.symbol} Value: ${token.data.usdPrice*rewards[1][i]/100000000000000000} `);
        i++;
    }
       
}

main();

