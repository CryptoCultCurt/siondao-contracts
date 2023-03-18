const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;

    await deployProxy("StrategyVenusBusd", deployments, save);
    console.log('deployed Venus Strategy')



};

module.exports.tags = ['strategy','StrategyVenusBusd'];


