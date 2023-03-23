
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const venusstrat = await constants.getContract("StrategyVenusBusd");
    const exchange = await constants.getContract('Exchange');
    const pm = await constants.getContract('PortfolioManager');

    let busdToken = await venusstrat.busdToken();
    let vBusdToken = await venusstrat.vBusdToken();
    let unitroller = await venusstrat.unitroller();
    let  pancakeRouter =  await venusstrat.pancakeRouter();
    let xvsToken = await venusstrat.xvsToken();
    let wbnbToken = await venusstrat.wbnbToken();
    const portfolioManager = await venusstrat.portfolioManager();
    const PORTFOLIO_MANAGER = await venusstrat.PORTFOLIO_MANAGER();
    const pmRole = await venusstrat.hasRole(PORTFOLIO_MANAGER,portfolioManager);


    console.log(`\nVenusBUSD Strategy:
    BUSD:       ${busdToken}
    vBUSD:      ${vBusdToken}
    unitroller: ${unitroller}
    router:     ${pancakeRouter}
    xvsToken:   ${xvsToken}
    wBNBToken:  ${wbnbToken}
    PM:         ${portfolioManager} (${pmRole})
    `)

    const vBusd = await util.getERC20ByAddress(vBusdToken, wallet);
    const busd = await util.getERC20ByAddress(busdToken, wallet);
  
    const balance = await vBusd.balanceOf(venusstrat.address);
    const balanceBusd = await busd.balanceOf(venusstrat.address);
    const nav = await venusstrat.netAssetValue();
 
    console.log(`Balances:
    vBUSD:                  ${balance}
    BUSD:                   ${balanceBusd}
    Net Asset Value:        ${nav}
    BUSD Portfolio Manager: ${await busd.balanceOf(pm.address)}
    `)
}

main();

