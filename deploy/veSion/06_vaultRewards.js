const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('RewardsVault', deployments, save);
};

module.exports.tags = ['vesion','RewardsVault'];
