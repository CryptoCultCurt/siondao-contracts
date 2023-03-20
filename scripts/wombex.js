
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

    const venusstrat = await constants.getContract("StrategyWombexBusd");
    const exchange = await constants.getContract('Exchange');
    const pm = await constants.getContract('PortfolioManager');

    let busdToken = await venusstrat.busdToken();
    let lpBusdToken = await venusstrat.lpBusdToken();
    let poolDepositor = await venusstrat.poolDepositor();
    let  wombatRouter =  await venusstrat.wombatRouter();
    let xvsToken = await venusstrat.womToken();
    let wbnbToken = await venusstrat.wbnbToken();
    let wmxLpToken = await venusstrat.wmxLpToken();

    const portfolioManager = await venusstrat.portfolioManager();
    const PORTFOLIO_MANAGER = await venusstrat.PORTFOLIO_MANAGER();
    const pmRole = await venusstrat.hasRole(PORTFOLIO_MANAGER,portfolioManager);


    console.log(`\nVenusBUSD Strategy:
    BUSD:           ${busdToken}
    lpBusdToken:    ${lpBusdToken}
    poolDepositor:  ${poolDepositor}
    wombatRouter:   ${wombatRouter}
    xvsToken:       ${xvsToken}
    wBNBToken:      ${wbnbToken}
    wmxLpToken:     ${wmxLpToken}
    PM:             ${portfolioManager} (${pmRole})
    `)

    const wmx = await util.getERC20ByAddress("0x6E85A35fFfE1326e230411f4f3c31c493B05263C", wallet);
    const busd = await util.getERC20ByAddress(busdToken, wallet);
  
    const balance =     await wmx.balanceOf(wallet);
    const balanceBusd = await busd.balanceOf(exchange.address);
    const nav =   0//      await venusstrat.netAssetValue();
 
    console.log(`Balances:
    wmx:                    ${balance}
    BUSD:                   ${balanceBusd}
    Net Asset Value:        ${nav}
    BUSD Portfolio Manager: ${await busd.balanceOf(pm.address)}

    ** NEED TO ADD REWARDS
    `)
}

main();

