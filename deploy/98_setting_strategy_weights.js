const {ethers} = require("hardhat");

let {DEFAULT} = require('../utils/assets');


module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const pm = await ethers.getContract("PortfolioManager");
    const exchange = await ethers.getContract("Exchange");

    const strategyAddr =  "0xA40Ac458f3A66bEf260a9184517F9eC8B0714117"
    const strategyAddr2 = "0x8b14e4A85aF501fb124439287196dA2E3cf3C13D"

    let asset;
    if (process.env.STAND === 'bsc') {
        asset = DEFAULT.busd;
    } else {
        asset = DEFAULT.usdc;
    }

    let strategy1 = {
        strategy: strategyAddr,
        minWeight: 0,
        targetWeight: 50000,
        maxWeight: 100000,
        riskFactor: 0,
        enabled: "true",
        enabledReward: "true",
    }

    let strategy2 = {
        strategy: strategyAddr2,
        minWeight: 0,
        targetWeight: "50000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let weights = [
        strategy1,
        strategy2
    ]

    console.log(`grant role`);
    console.log(deployer);
    let agentRole = await pm.PORTFOLIO_AGENT_ROLE();
    console.log('agentrole');
    console.log(agentRole);

    await (await pm.grantRole(agentRole, deployer)).wait();
    console.log(`add strategy`);
    await pm.addStrategy(strategyAddr);
    await pm.addStrategy(strategyAddr2);
    console.log(`add strategy weight`)
   // console.log(weights);
    await (await pm.setStrategyWeights(weights)).wait();
    console.log("portfolio.setWeights done");
    await (await pm.setCashStrategy(strategyAddr)).wait();
};

module.exports.tags = ['StrategyWeights'];

