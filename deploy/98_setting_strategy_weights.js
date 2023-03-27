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
    const strategyAddr5 = await ethers.getContract("StrategyWombexUsdt");

    let asset;
    if (process.env.STAND === 'bsc') {
        asset = DEFAULT.usdt;
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
        targetWeight: "25000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }


    let strategy3 = {
        strategy: strategyAddr3.address,
        minWeight: 0,
        targetWeight: "25000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let strategy4 = {
        strategy: strategyAddr4.address,
        minWeight: 0,
        targetWeight: "0",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let strategy5 = {
        strategy: strategyAddr5.address,
        minWeight: 0,
        targetWeight: "50000",
        maxWeight: "100000",
        riskFactor: 0,
        enabled: true,
        enabledReward: true,
    }

    let weights = [
       // strategy1,
       strategy2,
       strategy3,
     //  strategy4,
       strategy5
    ]


    let agentRole = await pm.PORTFOLIO_AGENT_ROLE();
    await (await pm.grantRole(agentRole, deployer)).wait();
   console.log('remove strategy');
//   await pm.removeStrategy(strategyAddr.address);
//  await pm.addStrategy(strategyAddr5.address);
//    await (await pm.setAsset("0x55d398326f99059fF775485246999027B3197955")).wait(); //USDT
//     //  await (await pm.setAsset("0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56")).wait(); // BUSD

//     await (await pm.setCashStrategy(strategyAddr5.address)).wait();

   

    console.log(`add strategy weight`)
    // console.log(weights);
    weights = [
        strategy2,
        strategy3,
        strategy4,
        strategy5
     ]
    await (await pm.setStrategyWeights(weights)).wait();
    console.log("portfolio.setWeights done");
    await pm.removeStrategy(strategyAddr4.address);
    weights = [
        strategy2,
        strategy3,
        strategy5
     ]
    await (await pm.setStrategyWeights(weights)).wait();
    console.log("portfolio.setWeights done");

    // await pm.removeStrategy(strategyAddr2.address);
    // await pm.removeStrategy(strategyAddr3.address);
    // weights = [

    //     strategy5
    //  ]
    //  await (await pm.setStrategyWeights(weights)).wait();
    //  console.log("portfolio.setWeights done");

    //  await pm.addStrategy(strategyAddr2.address);
    //  await pm.addStrategy(strategyAddr3.address);

    //  weights = [

    //     strategy5,
    //     strategy2,
    //     strategy3
    //  ]
    //  await (await pm.setStrategyWeights(weights)).wait();
    //  console.log("portfolio.setWeights done");


//  await (await pm.setAsset("0x55d398326f99059fF775485246999027B3197955")).wait(); //USDT
//     //  await (await pm.setAsset("0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56")).wait(); // BUSD
//     //  //
//      await (await pm.setCashStrategy(strategyAddr5.address)).wait();

};

module.exports.tags = ['StrategyWeights'];

