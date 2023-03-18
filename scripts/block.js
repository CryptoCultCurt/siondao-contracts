const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Time:        ${await helpers.time.latest()}`)
    console.log(`Chain:       ${chainId}`);

   await helpers.mine(28200, {interval: 3});

    console.log(`New Block:  ${await ethers.provider.getBlockNumber()}`);
    console.log(`New Time:   ${await helpers.time.latest()}`)

}

main();