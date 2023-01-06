const { ethers, upgrades } = require("hardhat");

// change these const as need
const AirdropContractName = "BtfsAirdrop"
const initializeParamValues =  ["0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD", "0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD", "0xFBA897eD8146F1f85c3eD4D9D078dA217E16B0A0"]

async function main() {
    // deploy implement contract
    console.log("Deploying implement...");
    const Airdrop = await ethers.getContractFactory(AirdropContractName);
    const airdrop = await upgrades.deployProxy(Airdrop, initializeParamValues, {
        kind: "uups",
        initializer: "initialize",
    })
    await airdrop.deployed()

    console.log("airdrop:", airdrop)
    console.log("airdrop deployed to:", airdrop.address)

    // let implAddr = await airdrop.getImplementation()
    // console.log("implementContract deployed to:", implAddr)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });