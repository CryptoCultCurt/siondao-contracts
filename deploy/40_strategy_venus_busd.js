const {deployProxy} = require("../utils/deployProxy");
const {BSC} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async ({deployments}) => {
    const {save} = deployments;

    await deploySection(async (name) => {
        console.log(`deploy ${name}`)
        await deployProxy(name, deployments, save);
    });
    console.log('do the settings')
   
    await settingSection(async (strategy) => {
        console.log('in it')
        await (await strategy.setParams(
            {
                busdToken: BSC.busd,
                vBusdToken: BSC.vBusd,
                unitroller: BSC.unitroller,
                pancakeRouter: BSC.pancakeRouter,
                xvsToken: BSC.xvs,
                wbnbToken: BSC.wBnb,
            }
        )).wait();
    });

};

module.exports.tags = ['strategy','StrategyVenusBusd'];
