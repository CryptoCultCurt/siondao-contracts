//const ethers = require('ethers');
const hre = require("hardhat");

async function main() {
    //hre.network = 'hardhat'
    let ethers = hre.ethers;
    let wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
    const [owner] = await ethers.getSigners();
    console.log(owner.address);
    console.log(await ethers.provider.getBlockNumber());
    const { chainId } = await ethers.provider.getNetwork();
    console.log(chainId);
    const Token = await ethers.getContractFactory("TestToken");
    //console.log(Token);
    const token = Token.attach("0xb8E4Ba456734A4562Ae5B4d3D81E525a9CB35100");
    let ownerBalance = 0;
    try {
        ownerBalance = await token.balanceOf(wallet)
    } catch (e) {
        console.log(e)
    }

    console.log(`Balance: ${(ownerBalance/1000000000000000000).toString()}`);
}

main();

