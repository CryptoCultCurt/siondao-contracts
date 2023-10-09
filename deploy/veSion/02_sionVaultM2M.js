const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('SionVaultM2M', deployments, save);
    console.log('Sion Vault Mark2Market deployed');
};

module.exports.tags = ['vesion','SionVaultM2M'];
