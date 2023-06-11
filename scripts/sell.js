const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");


async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";//constants.wallet;
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const exchange = await constants.getContract('Exchange');
    let usdt = await util.getERC20("usdt");

    
    let amount = "20000000000000000000000"; // 5000
    let referral = "";
    let params = [
        usdt.address,
        amount,
        referral
    ]

    let fromAddr = wallet;

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )

    const signer = await ethers.getSigner(wallet);
    await exchange.connect(signer).redeem(usdt.address,amount);


}

main();

