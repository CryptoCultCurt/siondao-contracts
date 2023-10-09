
const {ethers, upgrades} = require("hardhat");
const hre = require("hardhat");
const {getImplementationAddress} = require('@openzeppelin/upgrades-core');
const sampleModule = require('@openzeppelin/hardhat-upgrades/dist/utils/deploy-impl');
const fs = require('fs');
const {getContract, checkTimeLockBalance} = require("./script-utils");
const { formatUnits } = require("@ethersproject/units");


async function deployProxy(contractName, deployments, save, params) {
    return deployProxyMulti(contractName, contractName, deployments, save, params);
}





// export const deployContract = async (
//     contractFactory,
//     contractName = "Contract",
//     constructorArgs= [],
//     overrides = {},
// ) => {
//     const contract = (await contractFactory.deploy(...constructorArgs, overrides))
//     console.log(
//         `Deploying ${contractName} contract with hash ${contract.deployTransaction.hash} from ${
//             contract.deployTransaction.from
//         } with gas price ${contract.deployTransaction?.gasPrice?.toNumber() || 1 / 1e9} Gwei`,
//     )
//     const receipt = await contract.deployTransaction.wait()
//     const txCost = receipt.gasUsed.mul(contract.deployTransaction.gasPrice)
//     const abiEncodedConstructorArgs = contract.interface.encodeDeploy(constructorArgs)
//     console.log(
//         `Deployed ${contractName} to ${contract.address} in block ${receipt.blockNumber}, using ${
//             receipt.gasUsed
//         } gas costing ${formatUnits(txCost)} ETH`,
//     )
//     console.log(`ABI encoded args: ${abiEncodedConstructorArgs.slice(2)}`)
//     return contract
// }



async function deploy(contractName, deployments, save, params) {
    try {
        console.log('non proxy deploy from ' + hre.network.config.deployer + ' to ' + hre.network.config.network + ' network')
        console.log('params : ',params);
        console.log(deployments);
       
        const MyName = await ethers.getContractFactory(contractName);
       // console.log('MyName : ',MyName);
        const name = await MyName.deploy(
            contractName, {
                from: hre.network.config.deployer,
                args: [],
                log: true,}
        );
        await name.deployed();
        
        console.log(contractName + " deployed to:", name.address);
     
        await save(contractName, name.address);
    } catch (e) {
        console.log(e);
    }
    
};

async function deployProxyMulti(contractName, factoryName, deployments, save, params) {

    if (hre.ovn === undefined)
        hre.ovn = {};

    let factoryOptions;
    let unsafeAllow;
    let args;
    if (params) {
        factoryOptions = params.factoryOptions;
        unsafeAllow = params.unsafeAllow;
        args = params.args;
    }

    console.log(args);

    const contractFactory = await ethers.getContractFactory(factoryName, factoryOptions);

    //await upgrades.forceImport('0x5AfF5fF3b0190EC73a956b3aAFE57C3b85d35b37', contractFactory, args, {
    //    kind: 'uups',
    //    unsafeAllow: unsafeAllow
    //});

    let proxy;
    try {
        proxy = await ethers.getContract(contractName);
       //proxy = false;
    } catch (e) {
        console.log(`Proxy ${contractName} not found`);
       // console.log(e);
    }

    if (!proxy) {
        console.log(`Proxy ${contractName} not found`)
        console.log(args);
        proxy = await upgrades.deployProxy(contractFactory, args, {
            kind: 'uups',
            unsafeAllow: unsafeAllow
        });
        console.log(`Deploy ${contractName} Proxy progress -> ` + proxy.address + " tx: " + proxy.deployTransaction.hash);
        await proxy.deployTransaction.wait();
    } else {
        console.log(`Proxy ${contractName} found -> ` + proxy.address)
    }

    let impl;
    let implAddress;
    if (hre.ovn && !hre.ovn.impl) {
        // Deploy a new implementation and upgradeProxy to new;
        // You need have permission for role UPGRADER_ROLE;

        try {
            impl = await upgrades.upgradeProxy(proxy, contractFactory, {unsafeAllow: unsafeAllow});
        } catch (e) {
            impl = await upgrades.upgradeProxy(proxy, contractFactory, {unsafeAllow: unsafeAllow});
        }
        implAddress = await getImplementationAddress(ethers.provider, proxy.address);
        console.log(`Deploy ${contractName} Impl  done -> proxy [` + proxy.address + "] impl [" + implAddress + "]");
    } else {

        //Deploy only a new implementation without call upgradeTo
        //For system with Governance
        impl = await sampleModule.deployProxyImpl(hre, contractFactory, {
            kind: 'uups',
            unsafeAllow: unsafeAllow
        }, proxy.address);

        implAddress = impl.impl;
        console.log('Deploy impl done without upgradeTo -> impl [' + implAddress + "]");
    }


    if (impl && impl.deployTransaction)
        await impl.deployTransaction.wait();

    const artifact = await deployments.getExtendedArtifact(factoryName);
    artifact.implementation = implAddress;
    let proxyDeployments = {
        address: proxy.address,
        ...artifact
    }

    await save(contractName, proxyDeployments);


    // Enable verification contract after deploy
    if (hre.ovn.verify){

        console.log(`Verify proxy [${proxy.address}] ....`);

        try {
            await hre.run("verify:verify", {
                address: proxy.address,
                constructorArguments: [args],
            });
        } catch (e) {
            console.log(e);
        }


        console.log(`Verify impl [${impl.impl}] ....`);

        await hre.run("verify:verify", {
            address: impl.impl,
            constructorArguments: [],
        });
    }

    if (hre.ovn.gov){


        let timelock = await getContract('OvnTimelockController');

        hre.ethers.provider = new hre.ethers.providers.JsonRpcProvider('http://localhost:8545')
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [timelock.address],
        });

        const timelockAccount = await hre.ethers.getSigner(timelock.address);

        await checkTimeLockBalance();

        let contract = await getContract(contractName);
        await contract.connect(timelockAccount).upgradeTo(impl.impl);

        console.log(`[Gov] upgradeTo completed `)
    }


    return proxyDeployments;
}


module.exports = {
    deployProxy: deployProxy,
    deployProxyMulti: deployProxyMulti,
    deploy: deploy,
};
