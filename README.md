# airdrop

## Compile

This is a Tronbox project using the truffle plugin (for tests as this used to be truffle-based). 

```sh
tronbox compile
```

## Deploy

can specify the network to choose the network you want to deploy in tronbox.js. you can add --reset to redeploy contract.
```sh
tronbox migrate --network <network>
```

## Operation

deploy contracts will generate two contracts:Distributor and MerkleDistributor

1. call Distributor:upgradeCaller(MerkleDistributor.address) to set the caller from Owner
2. call MerkleDistributor:setMinter(Distributor.address) to set the minter from Owner
3. call MerkleDistributor:proposewMerkleRoot(root) to propose pending root from proposalAuthority
4. call MerkleDistributor:reviewPendingMerkleRoot(1) to review the pending root to root from reviewAuthority
5. transfer enough BTT to Distributor for airdrop

