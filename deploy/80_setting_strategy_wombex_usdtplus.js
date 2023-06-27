const { ethers } = require("hardhat");
const constants = require('../utils/constants');
let {DEFAULT, BSC, OPTIMISM, COMMON, ARBITRUM} = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const PM = await constants.getContract('PortfolioManager');
    const pm = PM.address;

    let wom = '0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1';
    let wmx = '0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD';
    let lpUsdtPlus = '0xbd459E33307A4ae92fFFCb45C6893084CFC273B1'; // USDT token address
    let wmxLpUsdtPlus = '0xf73dc098aeb7b61155770b8efba4c5291cd08bd6'; // wmxLP-USDT token address
    let poolDepositor = '0x0842c4431E4704a8740637cdc48Ab44D16C7Fe82'; // "Deposit contract address" // updated June 12,2023
    let pool = '0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0';

    let usdtPlus = '0x5335E87930b410b8C5BB4D43c3360ACa15ec0C8C';
    

    const venus_busd = await ethers.getContract("StrategyWombexUsdtPlus");
    let params = 
    {
        usdtPlus: usdtPlus,
        usdt: BSC.usdt,
        usdc: BSC.usdc,
        wom: wom,
        wmx: wmx,
        lpUsdtPlus: lpUsdtPlus,
        wmxLpUsdtPlus: wmxLpUsdtPlus,
        poolDepositor: poolDepositor,
        pool: pool,
        pancakeRouter: BSC.pancakeRouter,
        wombatRouter: BSC.wombatRouter,
        oracleUsdt: BSC.chainlinkUsdt,
        name: "Wombex USDT+"
    }
    await (await venus_busd.setParams(params)).wait();
    await venus_busd.setPortfolioManager(pm);
    const PORTFOLIO_MANAGER = await venus_busd.PORTFOLIO_MANAGER();
    await venus_busd.grantRole(PORTFOLIO_MANAGER,pm);
    console.log("Strategy Wombex_usdtPlus setParams done");
};

module.exports.tags = ['settingstrategy','SettingStrategyWombexUsdtPlus'];
