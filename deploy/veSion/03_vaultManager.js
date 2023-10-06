const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('SionVaultManager', deployments, save);
    console.log('Sion Vault Manager deployed');
};

module.exports.tags = ['vesion','SionVaultManager'];
