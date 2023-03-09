const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('StrategyThenaUsdtUsdPlus', deployments, save);

   console.log('deployed StrategyThenaUsdtUsdPlus')


};

module.exports.tags = ['strategy','StrategyThenaUsdtUsdPlus'];
