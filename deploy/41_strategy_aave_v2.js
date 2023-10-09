const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;

    await deployProxy("StrategyAaveV2", deployments, save);
    console.log('deployed Aave V2 Strategy')

};

module.exports.tags = ['sion','StrategyAaveV2'];


