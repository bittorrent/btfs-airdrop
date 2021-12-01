var Distributor = artifacts.require("Distributor.sol");
const BTTAddress = "TBWmwfchWFCcyASCytK2NAhHbWGwaJStLo";
const Caller = "TGHXNib6pkKjdvwn95Z7E9qA5HFRCc9D4J";
var MerkleDistributor = artifacts.require("MerkleDistributor.sol");

module.exports = async function(deployer) {

  deployer.deploy(Distributor, BTTAddress, Caller);
  
  deployer.deploy(MerkleDistributor, Caller, Caller);
};
