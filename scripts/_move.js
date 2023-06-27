const util = require('../utils/script-utils');
const constants = require('../utils/constants');
const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
      );
    const wallet = constants.wallet;
    const [owner,deployer,third] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const signer = await ethers.getSigner(owner.address);


    const token = await constants.getContract('SionToken');
    const EXCHANGER = await token.EXCHANGER();
    await token.grantRole(EXCHANGER,signer.address);
    await token.mint(signer.address,"5000000000000000000000");
    await token.burn(signer.address,"3000000000000000000000");


}

main();
