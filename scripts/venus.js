
const util = require('../utils/script-utils');
const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const VENUSSTRAT = await ethers.getContractFactory("StrategyVenusBusd");
    const venusstrat = VENUSSTRAT.attach("0xA40Ac458f3A66bEf260a9184517F9eC8B0714117");

    const EXCHANGE = await ethers.getContractFactory("Exchange");
    const exchange = EXCHANGE.attach("0x0c61a2be3465241c51145E99e2BEa5095BC566cf");

    const PM = await ethers.getContractFactory("PortfolioManager");
    const pm = PM.attach("0xac175f03294b8B46474423A8D4794b06b4b428d2");

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
    const balanceBusd = await busd.balanceOf(exchange.address);
    const nav = await venusstrat.netAssetValue();
 
    console.log(`
    
    Balances:
    vBUSD:                  ${balance}
    BUSD:                   ${balanceBusd}
    Net Asset Value:        ${nav}
    BUSD Portfolio Manager: ${await busd.balanceOf(pm.address)}
    `)
}

main();

