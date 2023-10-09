const { ethers } = require("hardhat");

let { DEFAULT } = require('../../utils/assets');


module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const vm = await ethers.getContract("CaviarVaultManager");
    const strategyAddr1 = await ethers.getContract("CaviarVaultStrategy");


    let weights = [{
        strategy: strategyAddr1.address,
        minWeight: 0,
        targetWeight: 100000,
        maxWeight: 100000,
        riskFactor: 0,
        enabled: "true",
        enabledReward: "true"
    }]

    let agentRole = await vm.PORTFOLIO_AGENT_ROLE();
    await (await vm.grantRole(agentRole, "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341")).wait();
    await vm.addStrategy(strategyAddr1.address);

    await (await vm.setCashStrategy(strategyAddr1.address)).wait();
    await (await vm.setStrategyWeights(weights)).wait();
    console.log("CaviarVault.setWeights done");

};

module.exports.tags = ['vesionsetting','StrategyWeightsCaviarVault'];

