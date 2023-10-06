
const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");
const {POLYGON} = require("../utils/assets.js");

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    let wallet = constants.wallet;
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);


    const exchange = await constants.getContract('Exchange');
    const pm = await constants.getContract('PortfolioManager');
    const m2m = await constants.getContract('Mark2Market');
    const token = await constants.getContract('Sion');

    const sionVault = await constants.getContract('SionVault');
    const sionVaultManager = await constants.getContract('SionVaultManager');
    const sionVaultStrategy = await constants.getContract('SionVaultStrategy');

    const caviarVaultStrategy = await constants.getContract('CaviarVaultStrategy');
    const caviarVault = await constants.getContract('CaviarVault');
    const caviarVaultManager = await constants.getContract('CaviarVaultManager');

    const rewardsVault = await constants.getContract('RewardsVault');


    console.log(`Contracts:
    Exchange:             ${exchange.address}
    Portfolio:            ${pm.address}
    M2M:                  ${m2m.address}
    Token:                ${token.address}

    SionVault:            ${sionVault.address}
    SionVaultManager:     ${sionVaultManager.address}
    SionVaultStrategy:    ${sionVaultStrategy.address}

    CaviarVault:          ${caviarVault.address}
    CaviarVaultManager:   ${caviarVaultManager.address}
    CaviarVaultStrategy:  ${caviarVaultStrategy.address}
    
    RewardsVault:         ${rewardsVault.address}

    `);



}

main();

