// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require("hardhat");

const SLICES = 8;
async function main() {
    const BtfsAirdrop = await ethers.getContractFactory("BtfsAirdrop");

    console.log("Deploying BtfsAirdrop...");

    const btfsAirdrop = await upgrades.deployProxy(BtfsAirdrop, [process.env.Proposal_Authority, process.env.Review_Authority], {
        initializer: "initialize",
    });
    await btfsAirdrop.deployed();

    console.log("BtfsAirdrop deployed to:", btfsAirdrop.address);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
