const { ethers } = require("hardhat");
const { utils } = ethers;

// change these const as need
const implementContractName = "BtfsAirdrop"
const proxyContractName = "BtfsAirdropProxy"
const initializeFuncname = "initialize"
const initializeParamTypes = ["address", "address", "address"]
const initializeParamValues =  ["0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD", "0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD", "0xFBA897eD8146F1f85c3eD4D9D078dA217E16B0A0"]

const proxyConstructorTypes = ["address", "bytes"]
const abiCoder = new utils.AbiCoder();

function encodeFunction(funcname = "", types = [], inputs = []) {
    let encoded = ""
    if (funcname !== "") {
        const sig = funcname + "(" + types.join(",") + ")";
        encoded += utils.hexDataSlice(utils.id(sig), 0, 4);
    }
    encoded += abiCoder.encode(types, inputs).slice(2);
    return encoded;
}
async function main() {
    // deploy implement contract
    console.log("Deploying implement...");
    const Impl = await ethers.getContractFactory(implementContractName);
    const impl = await Impl.deploy()
    await impl.deployed();
    console.log("Implement deployed to:", impl.address);
    // deploy proxy contract
    console.log("Deploying proxy...");
    const Proxy = await ethers.getContractFactory(proxyContractName);
    const initCall = encodeFunction(initializeFuncname, initializeParamTypes, initializeParamValues)
    console.log(initCall)
    const proxy = await Proxy.deploy(impl.address, initCall)
    await proxy.deployed();
    console.log("Proxy deployed to:", proxy.address);
    // print constructor parameter
    const constructorCall = encodeFunction("", proxyConstructorTypes, [impl.address, initCall])
    console.log("Constructor parameter: ", constructorCall)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });