
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

    const token = await constants.getContract('Sion');

    const decimals = await token.decimals();
    const exchange = await token.exchange();
    const liquidityIndex = await token.liquidityIndex();


    const ownerLength = await token.ownerLength();
    const totalMint = await token.totalMint();
    const totalSupply = await token.totalSupply();
    const name = await token.name();
    const symbol = await token.symbol();

    console.log(`
Token Settings:
    name:               ${name}
    symbol:             ${symbol}
    decimals:           ${decimals}
    exchange:           ${exchange}
    liquidityIndex:     ${ethers.utils.formatEther(liquidityIndex)}
    ownerLength:        ${ownerLength}
    totalMint:          ${ethers.utils.formatEther(totalMint)}
    totalSupply:        ${ethers.utils.formatEther(totalSupply)}
    `)


    let i=0;
    for (let i=0;i<ownerLength;i++) {
        let owner = await token.ownerAt(i);
        let balance = await token.ownerBalanceAt(i)
        console.log(`Owner#${i}:
        Owner:       ${owner}
        Balance:     ${ethers.utils.formatEther(balance)}
        `)
    }
}

main();

