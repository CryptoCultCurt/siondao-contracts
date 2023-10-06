const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('Mark2MarketVaults', deployments, save);
    console.log('Mark2Market deployed');
};

module.exports.tags = ['vesion','Mark2MarketVaults'];
