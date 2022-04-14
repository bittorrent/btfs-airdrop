# airdrop

## Deploy

deploy airdrop contract to BTTC network, copy the code of contracts to Remix, deploy it with metamask

## Operation

deploy contracts will generate one contract:MerkleDistributor


1. call MerkleDistributor:proposewMerkleRoot(root) to propose pending root from proposalAuthority
2. call MerkleDistributor:reviewPendingMerkleRoot(1) to review the pending root to root from reviewAuthority
3. call MerkleDistributor:setTotalAmount to set the total airdrop of this period
4. transfer enough WBTT to MerkleDistributor for airdrop





# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deployAutoProxy.js
npx hardhat help
```
