const {deployProxy} = require("../utils/deployProxy");
const {deploySection, settingSection} = require("../utils/script-utils");
const {BSC} = require("../utils/assets");



module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('StrategyWombexUsdt', deployments, save);
   

   
};

module.exports.tags = ['strategy','StrategyWombexUsdt'];