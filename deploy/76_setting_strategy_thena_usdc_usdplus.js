const { ethers } = require("hardhat");
let { BSC } = require('../utils/assets');
const constants = require('../utils/constants');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    let the = '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11';
    let pair = '0xea9abc7AD420bDA7dD42FEa3C4ACd058902A5845'; // usdt/usd+
    let router = '0x20a304a7d126758dfe6B243D0fc515F83bCA8431';
    let gauge = '0x31740dfF2D806690eDF3Ec72A2c301032a6265Bc'; // usdt/usd+
    let wombatPool = '0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0';
    let usdPlus = "0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65";
    
    const PM = await constants.getContract('PortfolioManager');
    const pm = PM.address;
    const venus_busd = await ethers.getContract("StrategyThenaUsdtUsdPlus");

    let params = 
        {
            busdToken: BSC.busd,
            usdtToken: BSC.usdt,
            usdPlus: usdPlus,
            the: the,
            pair: pair,
            router: router,
            gauge: gauge,
            wombatPool: wombatPool,
            wombatRouter: BSC.wombatRouter,
            oracleBusd: BSC.chainlinkBusd,
            oracleUsdt: BSC.chainlinkUsdt,
            usdPlusDm: "1000000",

        };


    await (await venus_busd.setParams(params)).wait();
    await venus_busd.setPortfolioManager(pm);
    const PORTFOLIO_MANAGER = await venus_busd.PORTFOLIO_MANAGER();
    await venus_busd.grantRole(PORTFOLIO_MANAGER,pm);
    console.log("Strategy SettingStrategyThenaUsdtUsdPlus setParams done");
};

module.exports.tags = ['setting','settingstrategy','SettingStrategyThenaUsdtUsdPlus'];
