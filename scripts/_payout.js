const hre = require("hardhat");

async function main() {
    let ethers = hre.ethers;
    hre.ethers.provider = new ethers.providers.JsonRpcProvider(hre.ethers.provider.connection.url);
    const provider = new ethers.providers.JsonRpcProvider(
        "http://localhost:8545"
        );
    let account = "0x564b06d31f2ae2745cae60be2ce4bf92477002c4";

    const [owner,deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Deployer:    ${deployer.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    const EXCHANGE = await ethers.getContractFactory("Exchange",owner);
    const exchange = EXCHANGE.attach("0x0c61a2be3465241c51145E99e2BEa5095BC566cf");
    const UNIT_ROLE = await exchange.UNIT_ROLE();
    const FREE_RIDER_ROLE = await exchange.PORTFOLIO_AGENT_ROLE();
    const DEFAULT_ADMIN_ROLE = await exchange.DEFAULT_ADMIN_ROLE();

    await exchange.grantRole(FREE_RIDER_ROLE, owner.address);
   await exchange.grantRole(UNIT_ROLE, owner.address);

          

     let tx = await (await exchange.payout()).wait();
     console.log('payout completed');
}

main();

