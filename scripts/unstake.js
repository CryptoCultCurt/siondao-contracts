const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    let wallet = constants.wallet;
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const strategy = await constants.getContract('StrategyThenawUsdrUsdc');
    //const strategy = await constants.getContract('StrategyThenaUsdtUsdPlus');

    const pm = await constants.getContract('PortfolioManager');
 
    const busd = await util.getERC20("busd");

    let asset = busd.address; 
    let amount = "100000000000"; // 5000
    let beneficiary = wallet;
   

    let fromAddr = wallet;
    const signer = await ethers.getSigner(fromAddr);
    const nav = await strategy.netAssetValue();
    console.log(nav.toString())
    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )
    
    const PORTFOLIO_MANAGER = await strategy.PORTFOLIO_MANAGER();
    await strategy.grantRole(PORTFOLIO_MANAGER, signer.address);



    await strategy.connect(signer).unstake(asset,amount,beneficiary,false);


}

main();

