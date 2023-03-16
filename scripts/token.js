
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

    const TOKEN = await ethers.getContractFactory("TestToken");
    const token = TOKEN.attach("0xb8E4Ba456734A4562Ae5B4d3D81E525a9CB35100");

    const decimals = await token.decimals();
    const exchange = await token.exchange();
    const liquidityIndex = await token.liquidityIndex();
    const name = await token.name();

    const ownerLength = await token.ownerLength();
    const totalMint = await token.totalMint();
    const totalSupply = await token.totalSupply();

    console.log(`
Token Settings:
    name:               ${name}
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

