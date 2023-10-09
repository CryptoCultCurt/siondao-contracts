const {deployProxy} = require("../../utils/deployProxy");
let { POLYGON } = require('../../utils/assets');

module.exports = async ({deployments}) => {
    const {save} = deployments;
    const cvr = POLYGON.cvr;
    const params = {args:["vexSionCVR","vexSionCVR",cvr]}
    await deployProxy('CaviarVaultStrategy', deployments, save, params);
    console.log('Caviar Strategy Vault deployed');
};

module.exports.tags = ['vesion','CaviarVaultStrategy'];
