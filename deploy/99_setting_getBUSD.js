const {ethers} = require("hardhat");
const {getERC20, getDevWallet, transferETH} = require("../utils/script-utils");
const {BSC} = require('../utils/assets');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deployer} = await getNamedAccounts();
    // 0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341
    // 0x5CB01385d3097b6a189d1ac8BA3364D900666445
    // 0x564B06D31f2aE2745caE60BE2cE4BF92477002C4 -- deployer
    await transferETH(10, '0x564B06D31f2aE2745caE60BE2cE4BF92477002C4'); // sends 10 bnb to account
    let holder = '0x5a52e96bacdabb82fd05763e25335261b270efcb'; // binance hot wallet

    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [holder],
    });

    let wallet = await getDevWallet();

    const tx = {
        from: wallet.address,
        to: holder,
        value: ethers.utils.parseEther('1'),
        nonce: await hre.ethers.provider.getTransactionCount(wallet.address, "latest"),
        gasLimit: 10000000,
        gasPrice: await hre.ethers.provider.getGasPrice(),
    }
    await wallet.sendTransaction(tx);

    const signerWithAddress = await hre.ethers.getSigner(holder);
    let busd = await getERC20("busd");
    //console.log(busd)
    console.log(`transfering ${await busd.balanceOf(holder)} to 0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341 `)
    await busd.connect(signerWithAddress).transfer(deployer, await busd.balanceOf(signerWithAddress.address));

    await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [holder],
    });

    let holder1 = '0x8894e0a0c962cb723c1976a4421c95949be2d4e3'; // binance hot wallet

    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [holder1],
    });

    const signerWithAddress1 = await hre.ethers.getSigner(holder1);
    let usdc = await getERC20("usdc");

    await usdc.connect(signerWithAddress1).transfer("0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341", await usdc.balanceOf(signerWithAddress1.address));
};

module.exports.tags = ['AddTokens'];
