const {deployProxy} = require("../../utils/deployProxy");
let { POLYGON } = require('../../utils/assets');

module.exports = async ({deployments}) => {
    const {save} = deployments;
    const cvr = POLYGON.cvr;
    const params = {args:["veSionCVR","veSionCVR",cvr]};
    await deployProxy('CaviarVault', deployments, save, params);
    console.log('CaviarVault deployed');
};

module.exports.tags = ['vesion','CaviarVault'];
