const {ethers} = require("hardhat");
const {getERC20} = require("../../utils/script-utils");
const {BSC} = require('../../utils/assets');
const constants = require('../../utils/constants');

const hre = require("hardhat");


async function main() {
    let ethers = hre.ethers;
    let wallet = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

   // const exchange = await constants.getContract('Exchange');
    let ul = await constants.getContract('UniversalLiquidator','localhost');
    console.log(`Address:     ${ul.address}`);
  
    

    async function setup() {
        console.log('set vault address');
        await ul.setPathRegistry("0x428dF72f181A05aab5b8533417E88cF45EE91722");
    }

   await setup();

   // const rewardTokens = await vault.rewardTokens();
    const pathRegistry = await ul.pathRegistry();
    




    console.log(`Universal Liquidator Settings:

    pathRegistry: ${pathRegistry}

    `);
   
   



}

main();