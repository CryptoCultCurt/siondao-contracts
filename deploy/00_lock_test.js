const {deployProxy} = require("../utils/deployProxy");
const hre = require("hardhat");
const {ethers} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    console.log('first step');
    const {deploy} = deployments;
    console.log('second step');
    const {deployer} = await getNamedAccounts();
    console.log(deployer);
    let params = {
        from: deployer,
        args: [Date.now()],
        log: true
    };
   // await deployProxy('Lock', deployments, save, params);
    await deploy('Lock', params)
  //  let usdPlus = await ethers.getContract('Lock');

    console.log('did it do something?')
    console.log('Lock deploy done()');


};

module.exports.tags = ['Lock'];
