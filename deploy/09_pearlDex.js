const {deployProxy,deploy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    
    await deploy('PearlDex', deployments, save);
};

module.exports.tags = ['vesion','PearlDex'];
// const hre = require("hardhat");

// module.exports = async ({getNamedAccounts, deployments}) => {
//     const {deploy} = deployments;
//   const {deployer} = await getNamedAccounts();

//     console.log(hre.network.config.deployer);
//     await deploy('PearlDex', 
//     {
//         from: deployer,
//         args: [],
//         log: true,
//     });
// };
