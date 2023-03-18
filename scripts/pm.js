
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

    const pm = await constants.getContract('PortfolioManager');

    const cashStrategy = await pm.cashStrategy();
    const exchanger = await pm.exchanger();
    const m2m = await pm.m2m();
    const totalRiskFactor = await pm.totalRiskFactor();

    console.log(`PM Settings:
    cashStrategy:       ${cashStrategy}
    exchanger:          ${exchanger}
    m2m:                ${m2m}
    totalRiskFactor:    ${totalRiskFactor}

    `)

    let weights = await pm.getAllStrategyWeights();
    let i=0;
    for (const weight of weights) {
        console.log(`Weight#${i}:
        Strategy:       ${weight.strategy}
        minWeight:      ${weight.minWeight.toString()}
        targetWeight:   ${weight.targetWeight.toString()}
        maxWeight:      ${weight.maxWeight.toString()}
        riskFactor:     ${weight.riskFactor.toString()}
        enabled:        ${weight.enabled}
        enabledReward:  ${weight.enabledReward}`)

        if (weight.enabled) {
            const strat= await ethers.getContractAt([{
                "inputs": [],
                "name": "netAssetValue",
                "outputs": [
                  {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                  }
                ],
                "stateMutability": "view",
                "type": "function"
              }],weight.strategy);

            const bal = await strat.netAssetValue();
            console.log(`        NetAssetValue:  ${(bal/1000000000000000000).toString()}`);
        }
        console.log('\n')
        i++;
    }
}

main();

