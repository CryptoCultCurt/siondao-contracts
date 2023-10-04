const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('SionVault', deployments, save);
};

module.exports.tags = ['vesion','Vault'];
