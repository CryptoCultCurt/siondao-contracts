const constants = require('../utils/constants');
const {getERC20} = require("../utils/script-utils");
const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    let wallet = constants.wallet;
    const [owner] = await ethers.getSigners();
    console.log(owner.address);
    console.log(await ethers.provider.getBlockNumber());
    const { chainId } = await ethers.provider.getNetwork();
    console.log(chainId);

    const token = await constants.getContract('TestToken');
    const busd = await getERC20('busd',wallet);
    let ownerBalance = 0;

    ownerBalance = await token.balanceOf(wallet)
    busdBalance = await busd.balanceOf(wallet);

    console.log(`Wallet Balance:
    Test Token: ${(constants.toDec18(ownerBalance)).toString()}
    BUSD:       ${(constants.toDec18(busdBalance)).toString()}
    `);
}

main();

