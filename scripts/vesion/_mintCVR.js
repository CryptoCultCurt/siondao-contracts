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
    const fromAddr = constants.cvrWhale;
    const toAddr = '0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341' //owner.address;//constants.wallet;
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
    let busd = await getERC20ByAddress("0x6AE96Cc93331c19148541D4D2f31363684917092",signer);
   // let usdc = await getERC20("usdc",await ethers.getSigner(toAddr));
    // await usdc.approve(
    //     Exchange.address,
    //     '10000000000000000000000000000'
    // )
        console.log('approval done');
    let busdBalance = (await busd.balanceOf(fromAddr)).toString();
    console.log(`Sending funds to ${toAddr}`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await signer.getBalance())} ETH`);
    console.log(`${fromAddr} has ${ethers.utils.formatEther(await busd.balanceOf(fromAddr))} CVR`);
    let amount = ethers.utils.parseEther("5.0");
    // const tx = {
    //     to: toAddr,
    //     value: ethers.utils.parseEther("500000")
    // }
    // await signer.sendTransaction(tx);
    await busd.transfer(
        toAddr,
        busdBalance
    )

    



};

main();