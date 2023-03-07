const { ethers } = require("hardhat");
let {DEFAULT, BSC, OPTIMISM, COMMON, ARBITRUM} = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const venus_busd = await ethers.getContract("StrategyVenusBusd");
    let params = 
        {
            busdToken: BSC.busd,
            vBusdToken: BSC.vBusd,
            unitroller: BSC.unitroller,
            pancakeRouter: BSC.pancakeRouter,
            xvsToken: BSC.xvs,
            wbnbToken: BSC.wBnb,
        };
    await (await venus_busd.setParams(params)).wait();
    console.log("Strategy Venus_busd setParams done");
};

module.exports.tags = ['setting','SettingStrategyVenusBusd'];
