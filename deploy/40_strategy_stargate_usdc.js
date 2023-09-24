const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;

    await deployProxy("StrategyStargateUsdc", deployments, save);
    console.log('deployed Stargate Strategy')

};

module.exports.tags = ['sion','StrategyStargateUsdc'];


