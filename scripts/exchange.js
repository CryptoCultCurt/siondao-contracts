
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

    const exchange = await constants.getContract('Exchange');

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
    console.log(`Exchange Settings:
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
    abroadmin:          ${await exchange.abroadMin()}
    abroadmax:          ${await exchange.abroadMax()}

    `)
}

main();

