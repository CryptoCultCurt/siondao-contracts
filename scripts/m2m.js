
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

    const m2m = await constants.getContract('Mark2Market');
    const pm = await m2m.portfolioManager();

    const totalLiquidationAssets = await m2m.totalLiquidationAssets();
    const totalNetAssets = await m2m.totalNetAssets();
    console.log(`M2MSettings:
    pm:                         ${pm}
    totalLiquidationAssets:     ${constants.toDec18(totalLiquidationAssets)}
    totalNetAssets:             ${constants.toDec18(totalNetAssets)}

    `)

    let weights = await m2m.strategyAssets();
    let i=0;
    for (const weight of weights) {
        console.log(`Strategy#${i}:
        Strategy:               ${weight.strategy}
        netAssetValue:          ${constants.toDec18(weight.netAssetValue).toString()}
        liquidationValue:       ${constants.toDec18(weight.liquidationValue).toString()}
        `)

        console.log('\n')
        i++;
    }
}

main();

