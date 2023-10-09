const {deployProxy} = require("../../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    const sion = await ethers.getContract("Sion");
    const params = {args:["veSion","veSion",sion.address]};
    await deployProxy('SionVault', deployments, save, params);
};

module.exports.tags = ['vesion','Vault'];
