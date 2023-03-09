const { ethers } = require("hardhat");
let { BSC } = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    let the = '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11';
    let pair = '0x6321B57b6fdc14924be480c54e93294617E672aB';
    let router = '0x20a304a7d126758dfe6B243D0fc515F83bCA8431';
    let gauge = '0x41adA56DD5702906549a71666541a39B0DbcEb12';
    let wombatPool = '0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0';
    let usdPlus = "0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65";

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
            oracleUsdt: BSC.chainlinkUsdt
        };


    await (await venus_busd.setParams(params)).wait();
    console.log("Strategy Venus_busd setParams done");
};

module.exports.tags = ['setting','SettingStrategyThenaUsdtUsdPlus'];
