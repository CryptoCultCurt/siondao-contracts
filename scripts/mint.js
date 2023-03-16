
const util = require('../utils/script-utils');
const hre = require("hardhat");
const { transferUSDPlus } = require('../utils/script-utils');

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const EXCHANGE = await ethers.getContractFactory("Exchange");
    const exchange = EXCHANGE.attach("0x0c61a2be3465241c51145E99e2BEa5095BC566cf");

    //console.log(exchange.address);

    let asset = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"; //busd
    let amount = "1000000000000000000000"; // 5000
    let referral = "";
    let params = [
        asset,
        amount,
        referral
    ]

    let fromAddr = "0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341"

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )

    const signer = await ethers.getSigner("0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341");
    let busd = await util.getERC20("busd",signer);
    await busd.connect(signer).approve(exchange.address,"500000000000000000000000");
    await exchange.connect(signer).mint(params);


}

main();

