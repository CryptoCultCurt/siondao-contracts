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
    const fromAddr = '0xf977814e90da44bfa03b6295a0616a897441acec'// binance wallet constants.whale;
    const toAddr = owner.address;//constants.wallet;
    const toAddr2 = '0x10444014ba4831fa355bc57b2d30a383baa11285';
    const toAddr3 = await constants.getContract('Exchange');

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )
    ethers.parseEther


    const signer = await ethers.getSigner(fromAddr);
    //const Exchange = await constants.getContract("Exchange");
    //console.log('exchange address: ' + Exchange.address);
    console.log('signer address: ' + signer.address);
    let busd = await getERC20("usdc",signer);
    let usdc = await getERC20("usdc",await ethers.getSigner(toAddr));
    // await usdc.approve(
    //     Exchange.address,
    //     '10000000000000000000000000000'
    // )
        console.log('approval done');
    let busdBalance = (await busd.balanceOf(fromAddr)).toString();
    console.log(`Sending funds to ${toAddr}`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await signer.getBalance())} ETH`);
    console.log(`${fromAddr} has ${constants.toDec18(busdBalance,9)} USDC`);
    //let amount = ethers.utils.parseEther("5.0");
    // const tx = {
    //     to: toAddr,
    //     value: ethers.utils.parseEther("500000")
    // }
   // await signer.sendTransaction(tx);
    const amount = '20000000000000';  // 20k
    await busd.transfer(
        toAddr,
        amount
    )
    console.log('transfer done to wallet %s', toAddr); 
    await busd.transfer(
        toAddr2,
        amount
    )
    console.log('transfer done to wallet %s', toAddr2);
    await busd.transfer(
        toAddr3.address,
        amount
    )
    console.log('transfer done to wallet %s', toAddr3.address);

    



};

main();