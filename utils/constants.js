const wallet = "0xeccb9b9c6fb7590a4d0588953b3170a1a84e3341";
const whale = '0x4b16c5de96eb2117bbe5fd171e4d203624b014aa'; // account to get busd from

async function getContract(contract) {
    const PM = await ethers.getContractFactory(contract);
    address = await hre.deployments.get(contract);
    return PM.attach(address.address);
}

async function getContractAt(contract,address) {
    const PM = await ethers.getContractFactory(contract);
    return await PM.attach(address);
}

function toDec18(number,decimals) {
    return number/1000000000000000000
}


module.exports.wallet = wallet;
module.exports.whale = whale;
module.exports.getContract = getContract;
module.exports.toDec18 = toDec18;
module.exports.getContractAt = getContractAt;