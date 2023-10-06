const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    // const params = {args:{
    //    "_nameArg":"duck",
    //    "_symbolArg":"fuzz",
    //    "_vaultManager":"0x000000",
    //     "_rewardTokens":["0x000000"],
    //     "_assetToBurn":0}
    // }
    const params = {args:["vexCVR","vexCVR"]}
   // PARAMS NOT SENT UNTIL CONTRACT FIXED
    await deployProxy('CaviarVaultStrategy', deployments, save);
    console.log('Caviar Strategy Vault deployed');
};

module.exports.tags = ['vesion','CaviarVaultStrategy'];
