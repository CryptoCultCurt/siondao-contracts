const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('CaviarStrategy', deployments, save);
};

module.exports.tags = ['vesion','VaultStrategy'];
