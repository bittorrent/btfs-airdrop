// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsAirdrop {
    using SafeMath for uint256;

    bytes32 public merkleRoot;
    bytes32 public pendingMerkleRoot;
    uint256 public lastTime;

    // admin address which can propose adding a new merkle root
    address public proposalAuthority;
    // admin address which approves or rejects a proposed merkle root
    address public reviewAuthority;
    address public owner;

    struct statistics {
        uint256 total;
        uint256 claimed;
    }
    // Record the total claim information of all period
    statistics  public totalClaimInfo;

    event Claimed(bytes32 merkleRootInput, uint256 index, address account, uint256 amount);
    event SetTotalAmount(bytes32 merkleRoot, uint256 amount);

    struct claimedOne {
        bytes32 lastMerkleRoot;
        uint256 claimed;
    }
    // which address, last epoch and claimed
    mapping(address => claimedOne) private claimedMap;

    constructor(address _proposalAuthority, address _reviewAuthority) {
        proposalAuthority = _proposalAuthority;
        reviewAuthority = _reviewAuthority;
        owner = msg.sender;
    }

    //    function init(address _proposalAuthority, address _reviewAuthority) public payable {
    //        proposalAuthority = _proposalAuthority;
    //        reviewAuthority = _reviewAuthority;
    //        owner = msg.sender;
    //    }

    // supply information
    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function upgradeOwner(address newOwner) external onlyOwner {
        require(newOwner != owner && newOwner != address(0), "invalid newOwner");
        owner = newOwner;
    }


    function setProposalAuthority(address _account) public {
        require(msg.sender == proposalAuthority);
        proposalAuthority = _account;
    }

    function setReviewAuthority(address _account) public {
        require(msg.sender == reviewAuthority);
        reviewAuthority = _account;
    }

    // set the total amount of airdrop this period
    function setTotalAmount(uint256 totalAmount) external onlyOwner {
        // Accumulate the total info
        totalClaimInfo.total = totalClaimInfo.total.add(totalAmount);

        emit SetTotalAmount(merkleRoot, totalAmount);
    }

    function getTotalClaimInfo() view external returns (uint256 total, uint256 claimed, bytes32 curMerkleRoot) {
        total = totalClaimInfo.total;
        claimed = totalClaimInfo.claimed;
        curMerkleRoot = merkleRoot;
    }

    function getUserClaimed() view external returns (uint256 userClaimed, bytes32 lastMerkleRoot) {
        userClaimed = claimedMap[msg.sender].claimed;
        lastMerkleRoot = claimedMap[msg.sender].lastMerkleRoot;
    }

    // Each week, the proposal authority calls to submit the merkle root for a new airdrop.
    function proposeMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == proposalAuthority);
        require(pendingMerkleRoot == 0x00);
        require(_merkleRoot != merkleRoot, "proposeMerkleRoot: merkleRoot is already used.");
        //require(block.timestamp >= lastRoot + 86400, "proposeMerkleRoot: it takes 1 day to modify it.");
        pendingMerkleRoot = _merkleRoot;
    }

    // After validating the correctness of the pending merkle root, the reviewing authority
    // calls to confirm it and the distribution may begin.
    function reviewPendingMerkleRoot(bool _approved) public {
        require(msg.sender == reviewAuthority);
        require(pendingMerkleRoot != 0x00);
        if (_approved) {
            merkleRoot = pendingMerkleRoot;

            lastTime = block.timestamp / 86400 * 86400;
        }
        delete pendingMerkleRoot;
    }

    function isUserClaimed(bytes32 merkleRootInput) public view returns (bool) {
        if (claimedMap[msg.sender].lastMerkleRoot == 0) {
            return false;
        }
        if (claimedMap[msg.sender].lastMerkleRoot == merkleRootInput) {
            return true;
        }

        return false;
    }

    function _setUserClaimed(uint256 amount) private {
        claimedMap[msg.sender].claimed = amount;
        claimedMap[msg.sender].lastMerkleRoot = merkleRoot;
    }

    function _getUserTransferAmount(uint256 amount) private view returns (uint256) {
        return amount.sub(claimedMap[msg.sender].claimed);
    }

    function claim(bytes32 merkleRootInput, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(0 < merkleProof.length, "claim: Invalid merkleProof");
        require(merkleRootInput == merkleRoot, "claim: Invalid merkleRootInput");
        require(!isUserClaimed(merkleRootInput), "claim: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoot, node), "claim: Invalid proof.");

        // get transfer amount
        uint256 transferAmount = _getUserTransferAmount(amount);

        // transfer to msg.sender
        payable(msg.sender).transfer(transferAmount);

        // Accumulate the total info
        totalClaimInfo.claimed = totalClaimInfo.claimed.add(transferAmount);

        // Mark it claimed amount
        _setUserClaimed(amount);

        emit Claimed(merkleRootInput, index, msg.sender, transferAmount);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

}