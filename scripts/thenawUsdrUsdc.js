
const util = require('../utils/script-utils');
const hre = require("hardhat");
const gaugeAbi = require('../utils/abi/ThenaGauge.json');
const poolAbi = require('../utils/abi/ThenaPool.json');
const constants = require('../utils/constants');

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    // contracts
    const venusstrat = await constants.getContract('StrategyThenawUsdrUsdc');
    const pm = await constants.getContract('PortfolioManager');
    const thenaPool = await ethers.getContractAt(poolAbi, await venusstrat.pair());
    const thenaGauge = await ethers.getContractAt(gaugeAbi, await venusstrat.gauge());

    let busdToken = await venusstrat.busd();
    let usdcToken = await venusstrat.usdc();
    let wUsdr = await venusstrat.wUsdr();
    let  the =  await venusstrat.the();
    let pair = await venusstrat.pair();
    let router = await venusstrat.router();
    let gauge = await venusstrat.gauge();
    let wombatPool = await venusstrat.wombatPool();
    let wombatRouter = await venusstrat.wombatRouter();
    let oracleBusd = await venusstrat.oracleBusd();
    let oracleUsdc = await venusstrat.oracleUsdc();
    
    const busd = await util.getERC20ByAddress(busdToken, wallet);
    const portfolioManager = await venusstrat.portfolioManager();
    const PORTFOLIO_MANAGER = await venusstrat.PORTFOLIO_MANAGER();
    const pmRole = await venusstrat.hasRole(PORTFOLIO_MANAGER,portfolioManager);

    console.log(`\Thena wUsdr Strategy:
    BUSD:           ${busdToken}
    USDC:           ${usdcToken}
    wUsdr:          ${wUsdr}
    the             ${the}
    pair            ${pair}
    router:         ${router}
    gauge:          ${gauge}
    wombatPool:     ${wombatPool}
    wombatRouter:   ${wombatRouter}
    oracleBusd:     ${oracleBusd}
    oracleUsdc:     ${oracleUsdc}
    PM:             ${portfolioManager} (${pmRole})
    `)

    const nav = await venusstrat.netAssetValue();
    const thenaBal = await thenaPool.balanceOf(venusstrat.address);
    const gaugeBal = await thenaGauge._balances(venusstrat.address);
    const rewards = await thenaGauge.rewards(venusstrat.address);
   

    console.log(`\nBalances:
    Net Asset Value:        ${nav/1000000000000000000}
    BUSD Portfolio Manager: ${await busd.balanceOf(pm.address)}
    Pool Balance:           ${thenaBal}
    Gauge Balance:          ${gaugeBal}
    Rewards:                ${rewards}
    `)
}

main();

