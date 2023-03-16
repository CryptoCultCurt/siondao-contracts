
const util = require('../utils/script-utils');
const hre = require("hardhat");
const { transferUSDPlus } = require('../utils/script-utils');

async function main() {
    let ethers = hre.ethers;
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const EXCHANGE = await ethers.getContractFactory("Exchange");
    const exchange = EXCHANGE.attach("0x0c61a2be3465241c51145E99e2BEa5095BC566cf");

    const mark2market = await exchange.mark2market();
    const insurance = await exchange.insurance();
    const lastBlockNumber = await exchange.lastBlockNumber();
    const nextPayoutTime = await exchange.nextPayoutTime();
    const oracleLoss = await exchange.oracleLoss();
    const payoutListener = await exchange.payoutListener();
    const portfolioManager = await exchange.portfolioManager();
    const profitRecipient = await exchange.profitRecipient();
    const usdPlus = await exchange.usdPlus(); 
    const usdc = await exchange.usdc(); 
    console.log(`
Exchange Settings:
    mark2market:        ${mark2market}
    insurance:          ${insurance}
    lastBlockNumber:    ${lastBlockNumber}
    nextPayoutTime:     ${nextPayoutTime}
    oracleLoss:         ${oracleLoss}
    payoutListener:     ${payoutListener}
    portfolioManager:   ${portfolioManager}
    profitRecipient:    ${profitRecipient}
    usdPlus:            ${usdPlus}
    usdc:               ${usdc}

    `)
}

main();

