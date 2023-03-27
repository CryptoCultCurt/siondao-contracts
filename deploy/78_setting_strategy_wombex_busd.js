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
let lpBusd = '0xF319947eCe3823b790dd87b0A509396fE325745a';
let wmxLpBusd = '0x6e85a35fffe1326e230411f4f3c31c493b05263c';
let poolDepositor = '0xF1fE1a695b4c3e2297a37523E3675603C0892b00';
let pool = '0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0';


    // 0xF319947eCe3823b790dd87b0A509396fE325745a wombat LP-BUSD
    // 0x6E85A35fFfE1326e230411f4f3c31c493B05263C wmxLP-BUSD
    // 0xF1fE1a695b4c3e2297a37523E3675603C0892b00 wombex busd deposit contract


    // call deposit function on wombex contract
    // sweep rewards from rewards contract
    // balanceOf wmxLP
    // claimableRewards wmxLP


    const venus_busd = await ethers.getContract("StrategyWombexBusd");
    let params = 
    {
        busd: BSC.busd,
        usdc: BSC.usdc,
        usdt: BSC.usdt,
        wom: wom,
        wmx: wmx,
        lpBusd: lpBusd,
        wmxLpBusd: wmxLpBusd,
        poolDepositor: poolDepositor,
        pool: pool,
        pancakeRouter: BSC.pancakeRouter,
        wombatRouter: BSC.wombatRouter,
        oracleBusd: BSC.chainlinkBusd,
        oracleUsdc: BSC.chainlinkUsdc,
    }
    await (await venus_busd.setParams(params)).wait();
    await venus_busd.setPortfolioManager(pm);
    const PORTFOLIO_MANAGER = await venus_busd.PORTFOLIO_MANAGER();
    await venus_busd.grantRole(PORTFOLIO_MANAGER,pm);
    console.log("Strategy Wombex_busd setParams done");
};

module.exports.tags = ['settingstrategy','SettingStrategyWombexBusd'];
