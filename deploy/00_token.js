const {deployProxy} = require("../utils/deployProxy");
const hre = require("hardhat");
const {ethers} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    console.log('first step');
    const { save } = deployments;
    console.log('second step');
    const {deployer} = await getNamedAccounts();
    console.log(deployer);
    let params = {args: ["Sion", "SION", 18]};
    
   // await deployProxy('Lock', deployments, save, params);
    await deployProxy('SionToken', deployments, save, params)
  //  let usdPlus = await ethers.getContract('Lock');

    console.log('Token deployed')


};

module.exports.tags = ['base','Token'];
