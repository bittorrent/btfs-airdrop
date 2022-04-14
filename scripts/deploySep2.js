const {ethers} = require("hardhat");
const {utils} = ethers;
const initializeFuncname = "initialize"
const initializeParamTypes = ["address", "address"]
const initializeParamValues = ["0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD", "0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD"]

const proxyConstructorTypes = ["address", "bytes"]
const abiCoder = new utils.AbiCoder();

function encodeFunction(funcname = "", types = [], inputs = []) {
    let encoded = ""
    if (funcname != "") {
        const sig = funcname + "(" + types.join(",") + ")";
        encoded += utils.hexDataSlice(utils.id(sig), 0, 4);
    }
    encoded += abiCoder.encode(types, inputs).slice(2);
    return encoded;
}


async function main() {
    // 1.btfsAirdrop
    const Logic = await ethers.getContractFactory("BtfsAirdrop");
    console.log("Deploying Logic...");
    const logic = await Logic.deploy()
    await logic.deployed();
    console.log("Deployed logic address:", logic.address);

    // 2.proxy
    const Proxy = await ethers.getContractFactory("BtfsAirdropProxy");
    const initCall = encodeFunction(initializeFuncname, initializeParamTypes, initializeParamValues);
    console.log("initCall = ", initCall)

    console.log("Deploying Proxy...");
    const proxy = await Proxy.deploy(logic.address, initCall);
    await proxy.deployed();
    console.log("Deployed proxy address:", proxy.address);

    // call proxy constructor
    const constructorCall = encodeFunction("constructor", proxyConstructorTypes, [logic.address, initCall]);
    console.log("constructorCall = ", constructorCall)
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
