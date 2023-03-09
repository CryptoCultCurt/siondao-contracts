
 //   args: ['0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c','0xd4ae6eCA985340Dd434D38F470aCCce4DC78D109','50'], 


const {deployProxy} = require("../utils/deployProxy");

module.exports = async ({deployments}) => {
    const {save} = deployments;
    await deployProxy('ThenaZap', deployments, save);
};

module.exports.tags = ['ThenaZap'];
