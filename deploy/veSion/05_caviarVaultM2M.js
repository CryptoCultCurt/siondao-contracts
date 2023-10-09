const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('CaviarVaultM2M', deployments, save);
    console.log('Caviar Vault Mark2Market deployed');
};

module.exports.tags = ['vesion','CaviarVaultM2M'];
