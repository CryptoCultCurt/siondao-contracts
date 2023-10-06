const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('CaviarVault', deployments, save);
    console.log('CaviarVault deployed');
};

module.exports.tags = ['vesion','CaviarVault'];
