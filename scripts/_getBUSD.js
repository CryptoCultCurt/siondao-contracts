const {ethers} = require("hardhat");
const {getERC20} = require("../utils/script-utils");
const {BSC} = require('../utils/assets');
const constants = require('../utils/constants');

async function main() {
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    const [owner,deployer] = await ethers.getSigners();
    const fromAddr = constants.whale;
    const toAddr = constants.wallet;

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )


    const signer = await ethers.getSigner(fromAddr);
  
    let busd = await getERC20("busd",signer);
    let busdBalance = (await busd.balanceOf(fromAddr)).toString();
    console.log(`Sending funds to ${toAddr}`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await signer.getBalance())} BNB`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await busd.balanceOf(fromAddr))} BUSD`);

    await busd.transfer(
        toAddr,
        busdBalance
    )




};

main();
