const {ethers} = require("hardhat");
const {getERC20,getERC20ByAddress} = require("../../utils/script-utils");
const {BSC} = require('../../utils/assets');
const constants = require('../../utils/constants');

async function main() {
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
      console.log('got provider');
   // const [owner,deployer] = await ethers.getSigners();
    const fromAddr = constants.usdrWhale;
    const toAddr =  constants.wallet;
    const toAddr2 = '0x10444014ba4831fa355bc57b2d30a383baa11285'
    console.log('got addresses', fromAddr, toAddr);
    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )
    ethers.parseEther


    const signer = await ethers.getSigner(fromAddr);
    console.log('got signer');
    //const Exchange = await constants.getContract("Exchange");
    //console.log('exchange address: ' + Exchange.address);
    console.log('signer address: ' + signer.address);
    let usdr = await getERC20ByAddress("0x40379a439D4F6795B6fc9aa5687dB461677A2dBa",signer);
   // let usdc = await getERC20("usdc",await ethers.getSigner(toAddr));
    // await usdc.approve(
    //     Exchange.address,
    //     '10000000000000000000000000000'
    // )
    console.log('approval done');
    let usdrBalance = (await usdr.balanceOf(fromAddr)).toString();
    console.log(`Sending funds to ${toAddr}`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await signer.getBalance())} ETH`);
    console.log(`${fromAddr} has ${constants.toDec18(await usdr.balanceOf(fromAddr),9)} USDR`);
    //let amount = ethers.utils.parseEther("5.0");
    // const tx = {
    //     to: toAddr,
    //     value: ethers.utils.parseEther("500000")
    // }
    // await signer.sendTransaction(tx);
    amountToSend = '10000000000000';
    await usdr.transfer(
        toAddr,
        amountToSend
    )

    await usdr.transfer(
        toAddr2,
        amountToSend
    )

    



};

main();