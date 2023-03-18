const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('StrategyThenawUsdrUsdc', deployments, save);

   console.log('deployed StrategyThenawUsdrUsdc')


};

module.exports.tags = ['strategy','StrategyThenawUsdrUsdc'];
