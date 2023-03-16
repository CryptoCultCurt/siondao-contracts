
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

    const M2M = await ethers.getContractFactory("Mark2Market");
    const m2m = M2M.attach("0xDd79122ebC68C43C4d9DBC16FDBd13F5b61F76ec");

    const pm = await m2m.portfolioManager();
    const totalLiquidationAssets = await m2m.totalLiquidationAssets();
    const totalNetAssets = await m2m.totalNetAssets();
    console.log(`
M2MSettings:
    pm:                         ${pm}
    totalLiquidationAssets:     ${totalLiquidationAssets}
    totalNetAssets:             ${totalNetAssets}

    `)

    let weights = await m2m.strategyAssets();

    let i=0;
    for (const weight of weights) {
        console.log(`Strategy#${i}:
        Strategy:               ${weight.strategy}
        netAssetValue:          ${weight.netAssetValue.toString()}
        liquidationValue:       ${weight.liquidationValue.toString()}
        `)

        console.log('\n')
        i++;
    }
}

main();

