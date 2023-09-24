const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('UniversalLiquidator', deployments, save);
};

module.exports.tags = ['vesion','UniversalLiquidator'];
