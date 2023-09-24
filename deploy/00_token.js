// const {deployProxy} = require("../utils/deployProxy");
// const hre = require("hardhat");
// const {ethers} = require("hardhat");

// module.exports = async ({getNamedAccounts, deployments}) => {
//     console.log('first step');
//     const { save } = deployments;
//     console.log('second step');
//     const {deployer} = await getNamedAccounts();
//     console.log(deployer);
//     let params = {args: ["Sion", "SION", 18]};
    
//    // await deployProxy('Lock', deployments, save, params);
//     await deployProxy('SionToken', deployments, save, params)
//   //  let usdPlus = await ethers.getContract('Lock');

//     console.log('Token deployed')


// };



// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// const hre = require("hardhat");

// async function main() {

//   const lock = await hre.ethers.deployContract("Sion", ["Sion", "SION", 18]);
//   await lock.waitForDeployment();

//   module.exports.tags = ['base','Token'];
   
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });