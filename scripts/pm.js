
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

    const PM = await ethers.getContractFactory("PortfolioManager");
    const pm = PM.attach("0xac175f03294b8B46474423A8D4794b06b4b428d2");

    const cashStrategy = await pm.cashStrategy();
    const exchanger = await pm.exchanger();
    const m2m = await pm.m2m();
    const totalRiskFactor = await pm.totalRiskFactor();
    console.log(`
PM Settings:
   
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
            console.log(`        NetAssetValue:  ${bal.toString()}`);
        }
        console.log('\n')
        i++;
    }
}

main();

