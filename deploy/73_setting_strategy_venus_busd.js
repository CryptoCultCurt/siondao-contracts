const { ethers } = require("hardhat");
const constants = require('../utils/constants');
let {DEFAULT, BSC, OPTIMISM, COMMON, ARBITRUM} = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const PM = await constants.getContract('PortfolioManager');
    const pm = PM.address;

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
