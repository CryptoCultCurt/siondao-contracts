const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('CaviarVaultManager', deployments, save);
    console.log('Caviar Vault Manager deployed');
};

module.exports.tags = ['vesion','CaviarVaultManager'];
