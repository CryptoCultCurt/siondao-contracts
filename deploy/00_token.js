const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    const params = {args: ["Sion", "SION", 18]};
    await deployProxy('Sion', deployments, save, params);
};

module.exports.tags = ['sion','Token'];