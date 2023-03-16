const { ethers } = require("hardhat");
let {DEFAULT, BSC, OPTIMISM, COMMON, ARBITRUM} = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const pm = "0xac175f03294b8B46474423A8D4794b06b4b428d2";

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
    await venus_busd.setPortfolioManager(pm);
    const PORTFOLIO_MANAGER = await venus_busd.PORTFOLIO_MANAGER();
    await venus_busd.grantRole(PORTFOLIO_MANAGER,pm);
    console.log("Strategy Venus_busd setParams done");
};

module.exports.tags = ['setting','SettingStrategyVenusBusd'];
