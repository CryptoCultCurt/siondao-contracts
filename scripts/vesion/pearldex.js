const { ethers } = require("hardhat");
const { getERC20, getERC20ByAddress } = require("../../utils/script-utils");
const { POLYGON } = require('../../utils/assets');
const constants = require('../../utils/constants');
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");


async function main() {

  let wallet = '0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341';
  const [owner, deployer] = await ethers.getSigners();
  const { chainId } = await ethers.provider.getNetwork();
  console.log(`\nOwner:       ${owner.address}`);
  // console.log(`Deployer:    ${deployer.address}`);
  console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
  console.log(`Chain:       ${chainId}`);

  // const exchange = await constants.getContract('Exchange');
  let sionVault = await constants.getContract('SionVault', 'localhost');
  let sionVaultStrategy = await constants.getContract('SionVaultStrategy', 'localhost');
  let sionVaultManager = await constants.getContract('SionVaultManager', 'localhost');
  let sionM2M = await constants.getContract('Mark2MarketVaults', 'localhost');
  let pearlDex = await constants.getContract('PearlDex', 'localhost');

  pearlDex.pairSetup(POLYGON.usdc, POLYGON.usdr,true);





  console.log(`


    `);



}

main();