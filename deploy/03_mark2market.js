const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('Mark2Market', deployments, save);
};

module.exports.tags = ['sion','Mark2Market'];
