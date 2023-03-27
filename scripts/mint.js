
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");

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
    const usdt = await util.getERC20("usdt",signer);
    console.log(`Wallet USDT: ${await usdt.balanceOf(wallet)/1000000000000000000}`)

    let asset = usdt.address; 
    let amount = "500000000000000000000"; // 5000
    let referral = "";
    let params = [
        asset,
        amount,
        referral
    ]

    let fromAddr = wallet;

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )

    await usdt.connect(signer).approve(exchange.address,"50000000000000000000000000");
    await exchange.connect(signer).mint(params);


}

main();

