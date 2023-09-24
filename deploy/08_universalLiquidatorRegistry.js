const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('UniversalLiquidatorRegistry', deployments, save);
};

module.exports.tags = ['vesion','UniversalLiquidatorRegistry'];

