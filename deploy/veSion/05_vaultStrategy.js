const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    const sion = await ethers.getContract("Sion");
    const params = {args:["vexSion","vexSion",sion.address]};
    await deployProxy('SionVaultStrategy', deployments, save, params);
};

module.exports.tags = ['vesion','SionVaultStrategy'];
