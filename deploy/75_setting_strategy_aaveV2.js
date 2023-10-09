const {deployProxy} = require("../utils/deployProxy");
const {POLYGON} = require('../utils/assets');
const {deploySection, settingSection} = require("../utils/script-utils");

module.exports = async () => {

    const strategy = await ethers.getContract("StrategyAaveV2");
    const pm = await ethers.getContract("PortfolioManager");

        await (await strategy.setTokens(POLYGON.usdc, '0x625E7708f30cA75bfd92586e17077590C60eb4cD')).wait(); // USDC,aPolUSDC
        await (await strategy.setParams('0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb')).wait(); // updated to v3
        await strategy.setPortfolioManager(pm.address);
        console.log('set params done')

};

module.exports.tags = ['sionsetting','StrategyAaveV2Setting'];
