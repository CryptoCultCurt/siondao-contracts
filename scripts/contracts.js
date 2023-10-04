
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

    const vault = await constants.getContract('VaultERC4626');
    const strategy = await constants.getContract('CaviarStrategy');
    const rewardsVault = await constants.getContract('CaviarStrategy');


    console.log(`Contracts:
    Exchange:       ${exchange.address}
    Portfolio:      ${pm.address}
    M2M:            ${m2m.address}
    Token:          ${token.address}

    Vault:          ${vault.address}
    Strategy:       ${strategy.address}
    RewardsVault:   ${rewardsVault.address}
    
    `)


}

main();

