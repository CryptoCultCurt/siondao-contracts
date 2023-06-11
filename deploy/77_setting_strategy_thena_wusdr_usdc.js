const { ethers } = require("hardhat");
let { BSC } = require('../utils/assets');
const constants = require('../utils/constants');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    let the = '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11';
    let pair = '0xA99c4051069B774102d6D215c6A9ba69BD616E6a'; // wUsdr/usdc
    let router = '0x20a304a7d126758dfe6B243D0fc515F83bCA8431';
    let gauge = '0x867a89cb8eb42007ce2af9d7089cdabc7840f11b'; // wUsdr/usdc
    let wombatPool = '0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0';
    let wUsdr = "0x2952beb1326acCbB5243725bd4Da2fC937BCa087";
    
    const PM = await constants.getContract('PortfolioManager');
    const pm = PM.address;
    const venus_busd = await ethers.getContract("StrategyThenawUsdrUsdc");

    let params = 
        {
            busdToken: BSC.busd,
            usdcToken: BSC.usdc,
            wUsdr: wUsdr,
            the: the,
            pair: pair,
            router: router,
            gauge: gauge,
            wombatPool: wombatPool,
            wombatRouter: BSC.wombatRouter,
            oracleBusd: BSC.chainlinkBusd,
            oracleUsdc: BSC.chainlinkUsdc,
            wUsdrDm: "1000000000",
            usdtToken: BSC.usdt,
            oracleUsdt: BSC.chainlinkUsdt,
            name: "Thena wUsdr/Usdc"

        };
        console.log(params);

    await (await venus_busd.setParams(params)).wait();
    await venus_busd.setPortfolioManager(pm);
    const PORTFOLIO_MANAGER = await venus_busd.PORTFOLIO_MANAGER();
    await venus_busd.grantRole(PORTFOLIO_MANAGER,pm);
    console.log("Strategy SettingStrategyThenawUsdrUsdc setParams done");
};

module.exports.tags = ['settingstrategy','SettingStrategyThenawUsdrUsdc'];
