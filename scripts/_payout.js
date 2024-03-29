const hre = require("hardhat");
const constants = require('../utils/constants');

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner,deployer] = await ethers.getSigners();
    console.log(owner.address);
    console.log(await ethers.provider.getBlockNumber());
    const { chainId } = await ethers.provider.getNetwork();

    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const exchange = await constants.getContract('Exchange');
    const UNIT_ROLE = await exchange.UNIT_ROLE();
    const FREE_RIDER_ROLE = await exchange.PORTFOLIO_AGENT_ROLE();


    await exchange.grantRole(FREE_RIDER_ROLE, owner.address);
    await exchange.grantRole(UNIT_ROLE, owner.address);

    let tx = await (await exchange.payout()).wait();
    console.log(`Hash: ${tx.transactionHash}`);
    console.log(`Gas Used: ${tx.gasUsed.toString()}`);
    console.log('payout completed');
}

main();

