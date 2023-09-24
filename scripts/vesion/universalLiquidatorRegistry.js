/* [0x1eBA8CF895d78b9cE7fE2645601C82F9A1d86A87, // CVR to USDR
    0x6AE96Cc93331c19148541D4D2f31363684917092,
    0x7238390d5f6F64e67c3211C343A410E2A3DEc142,
    0x40379a439D4F6795B6fc9aa5687dB461677A2dBa]
*/

// 0x40379a439D4F6795B6fc9aa5687dB461677A2dBa  USDR

// sell USDR to USDC
// universalLuquidatorRegistry
// addDex('Uniswap',0x983c77929979f633F0043D3B1070b460688E9c0e)
// setPath('Uniswap',[0x40379a439d4f6795b6fc9aa5687db461677a2dba,0x2791bca1f2de4661ed88a30c99a7a9449aa84174])
// this is a "universal" router, aka, custom middleware.  set it up directly for pearl



// these use pearl dex
// pearl -> caviar -> eth
// pearl -> caviar 
// usdr -> eth (0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619)
// usdr (0x40379a439D4F6795B6fc9aa5687dB461677A2dBa) -> pearl (0x7238390d5f6F64e67c3211C343A410E2A3DEc142) -> caviar (0x6AE96Cc93331c19148541D4D2f31363684917092)
// caviar -> pearl -> usdr
// pearl dex 0x983c77929979f633F0043D3B1070b460688E9c0e

const { ethers } = require("hardhat");
const { getERC20 } = require("../../utils/script-utils");
const { BSC, POLYGON } = require('../../utils/assets');
const constants = require('../../utils/constants');

const hre = require("hardhat");


async function main() {
    let ethers = hre.ethers;
    let wallet = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const [owner, deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    console.log(`\nOwner:       ${owner.address}`);
    console.log(`Block:       ${await ethers.provider.getBlockNumber()}`);
    console.log(`Chain:       ${chainId}`);

    // const exchange = await constants.getContract('Exchange');
    let ulr = await constants.getContract('UniversalLiquidatorRegistry', 'localhost');
    console.log(`Address:     ${ulr.address}`);



    async function setup() {
        console.log('setup dex');
        const name = ethers.utils.formatBytes32String('Uniswap');
        console.log(name);
        await ulr.addDex(name, "0x983c77929979f633F0043D3B1070b460688E9c0e");
        console.log('dex added');
    }

    //await setup();
   // DONE await ulr.setPath('0x556e697377617000000000000000000000000000000000000000000000000000',['0x40379a439D4F6795B6fc9aa5687dB461677A2dBa','0x7238390d5f6F64e67c3211C343A410E2A3DEc142','0x6AE96Cc93331c19148541D4D2f31363684917092']);
    // 092-dba
    await ulr.setPath('0x556e697377617000000000000000000000000000000000000000000000000000',['0x6AE96Cc93331c19148541D4D2f31363684917092','0x7238390d5f6F64e67c3211C343A410E2A3DEc142','0x40379a439D4F6795B6fc9aa5687dB461677A2dBa']);
    
    // const rewardTokens = await vault.rewardTokens();
    // const pathRegistry = await ul.pathRegistry();
    const dexes = await ulr.getAllDexes();
    console.log(`Universal Liquidator Registry Settings:
        dexes: ${dexes}
    `);
}

main();

// {
//     "func": "swapExactTokensForTokens",
//     "params": [
//         1000000000000000000,
//         403689185,
//         [
//             [
//                 "0x6AE96Cc93331c19148541D4D2f31363684917092",
//                 "0x7238390d5f6F64e67c3211C343A410E2A3DEc142",
//                 false
//             ],
//             [
//                 "0x7238390d5f6F64e67c3211C343A410E2A3DEc142",
//                 "0x40379a439D4F6795B6fc9aa5687dB461677A2dBa",
//                 false
//             ]
//         ],
//         "0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341",
//         1695347176
//     ]
// }