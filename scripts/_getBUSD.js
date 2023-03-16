const {ethers} = require("hardhat");
const {getERC20, getDevWallet, transferETH} = require("../utils/script-utils");
const {BSC} = require('../utils/assets');

async function main() {
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    const [owner,deployer] = await ethers.getSigners();
    const fromAddr = "0xd2f93484f2d319194cba95c5171b18c1d8cfd6c4";
    const toAddr = "0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341";

    await provider.send(
        "hardhat_impersonateAccount",
       [fromAddr]
    )


    const signer = await ethers.getSigner(fromAddr);
    /// TRANSFER ETH
    // const tx = {
    //     to: deployer.address,
    //     value: ethers.utils.parseEther("10"),
    // }
    // const receiptTx = await signer.sendTransaction(tx);
    // console.log(receiptTx);
////

    console.log(`fromAddr has ${ethers.utils.formatEther(await signer.getBalance())} BNB`);

    let busd = await getERC20("busd",signer);
    let busdBalance = (await busd.balanceOf(fromAddr)).toString();
    console.log(`busd balnce from: ${busdBalance}`);
    console.log(`transfering ${ethers.utils.formatEther=(await busd.balanceOf(fromAddr))} in BUSD to ${toAddr} `);
    await busd.transfer(
        toAddr,
        busdBalance
    )




};

main();
