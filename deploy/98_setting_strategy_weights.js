const {ethers} = require("hardhat");

let {DEFAULT} = require('../utils/assets');


module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const pm = await ethers.getContract("PortfolioManager");
    const exchange = await ethers.getContract("Exchange");

    const strategyAddr1 =  await ethers.getContract("StrategyAaveV2");
    // const strategyAddr2 = await ethers.getContract("StrategyThenaUsdtUsdPlus");
    // const strategyAddr3 = await ethers.getContract("StrategyThenawUsdrUsdc");
    // const strategyAddr4 = await ethers.getContract("StrategyWombexBusd");
    // const strategyAddr5 = await ethers.getContract("StrategyWombexUsdt");
    // const strategyAddr6 = await ethers.getContract("StrategyWombexUsdtPlus");


    let asset;
    if (process.env.STAND === 'bsc') {
        asset = DEFAULT.usdt;
    } else {
        asset = DEFAULT.usdc;
    }

    let strategy1 = {
        strategy: strategyAddr1.address,
        minWeight: 0,
        targetWeight: 100000,
        maxWeight: 100000,
        riskFactor: 0,
        enabled: "true",
        enabledReward: "true",
    }

    // let strategy2 = {
    //     strategy: strategyAddr2.address,
    //     minWeight: 0,
    //     targetWeight: 0,
    //     maxWeight: 10000,
    //     riskFactor: 0,
    //     enabled: true,
    //     enabledReward: true,
    // }


    // let strategy3 = {
    //     strategy: strategyAddr3.address,
    //     minWeight: 0,
    //     targetWeight: 0,
    //     maxWeight: 100000,
    //     riskFactor: 0,
    //     enabled: true,
    //     enabledReward: true,
    // }

    // let strategy4 = {
    //     strategy: strategyAddr4.address,
    //     minWeight: 0,
    //     targetWeight: "0",
    //     maxWeight: 100000,
    //     riskFactor: 0,
    //     enabled: true,
    //     enabledReward: true,
    // }

    // let strategy5 = {
    //     strategy: strategyAddr5.address,
    //     minWeight: 0,
    //     targetWeight: 100000,
    //     maxWeight: 100000,
    //     riskFactor: 0,
    //     enabled: true,
    //     enabledReward: true,
    // }

    // let strategy6 = {
    //     strategy: strategyAddr6.address,
    //     minWeight: 0,
    //     targetWeight: 0,
    //     maxWeight: "100000",
    //     riskFactor: 0,
    //     enabled: true,
    //     enabledReward: true,
    // }

    let weights = [
       strategy1
    ]


    let agentRole = await pm.PORTFOLIO_AGENT_ROLE();
    let agentRole2 = await strategyAddr1.PORTFOLIO_MANAGER();
    await (await pm.grantRole(agentRole, "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341")).wait();
    await (await pm.grantRole(agentRole2, "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341")).wait();

    try {
        await pm.addStrategy(strategyAddr1.address);
    } catch(e) {
        console.log('strategy was added previously or an errror occured');
    }

    await (await pm.setCashStrategy(strategyAddr1.address)).wait();
    await (await pm.setStrategyWeights(weights)).wait();
    console.log("portfolio.setWeights done");
   

  //  console.log(`add strategy weight`)
    // console.log(weights);
    // weights = [
    //     strategy2,
    //     strategy3,
    //     strategy4,
    //     strategy5
    //  ]

    // await pm.removeStrategy(strategyAddr4.address);
    // weights = [
    //     strategy2,
    //     strategy3,
    //     strategy5
    //  ]
    // await (await pm.setStrategyWeights(weights)).wait();
    // console.log("portfolio.setWeights done");

    // await pm.removeStrategy(strategyAddr2.address);
   //  await pm.removeStrategy(strategyAddr3.address);
    // await pm.addStrategy(strategyAddr6.address);
    // console.log('strategies removed');
    // weights = [

    //     strategy5,
    //     strategy6
    //  ]
    //  await (await pm.setStrategyWeights(weights)).wait();
    //  console.log("portfolio.setWeights done");

     // await pm.addStrategy(strategyAddr6.address);
    // await pm.removeStrategy(strategyAddr6.address);

    //  weights = [

    //   //  strategy2,
    //    // strategy3,
    //     strategy5,
    //     strategy6,
    //  ]
    //  await (await pm.setStrategyWeights(weights)).wait();
    //  console.log("portfolio.setWeights done");


//  await (await pm.setAsset("0x55d398326f99059fF775485246999027B3197955")).wait(); //USDT
//     //  await (await pm.setAsset("0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56")).wait(); // BUSD
//     //  //
//      await (await pm.setCashStrategy(strategyAddr5.address)).wait();

};

module.exports.tags = ['sionsetting', 'StrategyWeights'];

