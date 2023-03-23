const {ethers} = require("hardhat");

let {DEFAULT} = require('../utils/assets');


module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const pm = await ethers.getContract("PortfolioManager");
    const exchange = await ethers.getContract("Exchange");

    const strategyAddr =  await ethers.getContract("StrategyVenusBusd");
    const strategyAddr2 = await ethers.getContract("StrategyThenaUsdtUsdPlus");
    const strategyAddr3 = await ethers.getContract("StrategyThenawUsdrUsdc");
    const strategyAddr4 = await ethers.getContract("StrategyWombexBusd");

    let asset;
    if (process.env.STAND === 'bsc') {
        asset = DEFAULT.busd;
    } else {
        asset = DEFAULT.usdc;
    }

    let strategy1 = {
        strategy: strategyAddr.address,
        minWeight: 0,
        targetWeight: 0,
        maxWeight: 10000,
        riskFactor: 0,
        enabled: "false",
        enabledReward: "false",
    }

    let strategy2 = {
        strategy: strategyAddr2.address,
        minWeight: 0,
        targetWeight: "35000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }


    let strategy3 = {
        strategy: strategyAddr3.address,
        minWeight: 0,
        targetWeight: "35000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let strategy4 = {
        strategy: strategyAddr4.address,
        minWeight: 0,
        targetWeight: "30000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let weights = [
        strategy1,
        strategy2,
        strategy3,
        strategy4
    ]


    let agentRole = await pm.PORTFOLIO_AGENT_ROLE();
    await (await pm.grantRole(agentRole, deployer)).wait();
    console.log(`add strategy`);
//    await pm.addStrategy(strategyAddr.address);
//   await pm.addStrategy(strategyAddr2.address);
//    await pm.addStrategy(strategyAddr3.address);
 //await pm.addStrategy(strategyAddr4.address);
    console.log(`add strategy weight`)
   // console.log(weights);
   await (await pm.setStrategyWeights(weights)).wait();
    console.log("portfolio.setWeights done");
 //   await (await pm.setCashStrategy(strategyAddr4.address)).wait();
   await pm.removeStrategy(strategyAddr.address);
};

module.exports.tags = ['StrategyWeights'];

