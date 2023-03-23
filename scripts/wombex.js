
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

    const venusstrat = await constants.getContract("StrategyWombexBusd");
    const exchange = await constants.getContract('Exchange');
    const pm = await constants.getContract('PortfolioManager');

    let busdToken = await venusstrat.busd();
    let lpBusdToken = await venusstrat.lpBusd();
    let poolDepositor = await venusstrat.poolDepositor();
    let  wombatRouter =  await venusstrat.wombatRouter();
    let womToken = await venusstrat.wom();
    let wmxLpToken = await venusstrat.wmxLpBusd();
    let wmx = await venusstrat.wmx();


    const portfolioManager = await venusstrat.portfolioManager();
    const PORTFOLIO_MANAGER = await venusstrat.PORTFOLIO_MANAGER();
    const pmRole = await venusstrat.hasRole(PORTFOLIO_MANAGER,portfolioManager);


    console.log(`\nVenusBUSD Strategy:
    BUSD:           ${busdToken}
    lpBusdToken:    ${lpBusdToken}
    poolDepositor:  ${poolDepositor}
    wombatRouter:   ${wombatRouter}
    womToken:       ${womToken}
    wmxLpToken:     ${wmxLpToken}
    PM:             ${portfolioManager} (${pmRole})
    `)

    const wmxContract = await ethers.getContractAt(wmxLPABI, wmxLpToken);
    const busd = await util.getERC20ByAddress(busdToken, venusstrat.address);
  
    const balance =     await wmxContract.balanceOf(venusstrat.address);
    const balanceBusd = await busd.balanceOf(exchange.address);
    const nav =  await venusstrat.netAssetValue();

    let rewards = await wmxContract.claimableRewards(venusstrat.address);

    let i=0;
    console.log(`Balances:
    wmx:                    ${balance}
    BUSD:                   ${balanceBusd}
    Net Asset Value:        ${nav}
    BUSD Portfolio Manager: ${await busd.balanceOf(pm.address)}
    Rewards:                `)
    for (reward of rewards[0]) {
        let token = await axios.get(`https://api.crypto-api.com/api/token/contract/${rewards[0][i]}/bsc`);
        console.log(`       Token: ${token.data.symbol} Value: ${token.data.usdPrice*rewards[1][i]/100000000000000000} `);
        i++;
    }
       
}

main();

