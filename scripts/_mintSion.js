
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");
const {POLYGON} = require("../utils/assets.js");

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    let wallet = constants.wallet;
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);


    const exchange = await constants.getContract('Exchange');
    const signer = await ethers.getSigner(wallet);
    const usdc = await util.getERC20("usdc",signer);
    console.log(usdc.address);
    console.log(`Wallet USDC: ${await usdc.balanceOf(wallet)/1000000000}`)

    let asset = usdc.address; 
    let amount = "5000000"; // 5000
    let referral = "";
    let params = [
        POLYGON.usdc,
        100000000000,
        0x000
    ]
// i got 99960 sion


    await usdc.connect(signer).approve(exchange.address,"50000000000000000000000000");
    //await exchange.connect(signer).redeem(asset,amount);
    await exchange.connect(signer).mint(params);


}

main();

