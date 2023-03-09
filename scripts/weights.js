//const ethers = require('ethers');
const hre = require("hardhat");

async function main() {
    //hre.network = 'hardhat'
    let ethers = hre.ethers;
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
    const [owner] = await ethers.getSigners();
    console.log(owner.address);
    console.log(await ethers.provider.getBlockNumber());
    const { chainId } = await ethers.provider.getNetwork();
    console.log(chainId);
    const PM = await ethers.getContractFactory("PortfolioManager");
    const pm = PM.attach("0xac175f03294b8B46474423A8D4794b06b4b428d2");

    let weights = await pm.getAllStrategyWeights();
    for (const weight of weights) {
        console.log(`
        Strategy: ${weight.strategy}
        targetWeight: ${weight.targetWeight.toString()}
        riskFactor:
        enabled:
        enabledReward:
        `)
    }
   // console.log(weights);
    //console.log(Token);
    //const token = Token.attach("0xb8E4Ba456734A4562Ae5B4d3D81E525a9CB35100");
    // let ownerBalance = 0;
    // try {
    //     ownerBalance = await token.balanceOf(wallet)
    // } catch (e) {
    //     console.log(e)
    // }

    // console.log(ownerBalance.toString());
}

main();

