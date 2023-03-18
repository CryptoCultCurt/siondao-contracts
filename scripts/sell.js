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

    const exchange = constants.getContract('Exchange');
    
    let amount = "1000000000000000000000"; // 5000
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

    const signer = await ethers.getSigner(wallet);
    let busd = await util.getERC20("busd",signer);
    await exchange.connect(signer).redeem(busd.address,"500000000000000000000");


}

main();

