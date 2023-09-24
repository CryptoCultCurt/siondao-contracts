const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('VaultERC4626', deployments, save);
};

module.exports.tags = ['vesion','Vault'];
