// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract Airdrop {
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

    event Claimed(uint256 epoch, uint256 index, address account, uint256 amount);
    event SetTotalAmount(bytes32 merkleRoot, uint256 amount);

    struct claimedOne {
        uint256 lastEpoch;
        uint256 claimed;
    }
    // which address, last epoch and claimed
    mapping(address => claimedOne) private claimedMap;

    constructor(address _proposalAuthority, address _reviewAuthority) {
        proposalAuthority = _proposalAuthority;
        reviewAuthority = _reviewAuthority;
        owner = msg.sender;
    }

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

    function isClaimed(uint256 epoch) public view returns (bool) {
        if (claimedMap[msg.sender].lastEpoch == 0) {
            return false;
        }
        if (claimedMap[msg.sender].lastEpoch >= epoch) {
            return true;
        }

        return false;
    }

    function _setClaimed(uint256 epoch, uint256 amount) private {
        if (claimedMap[msg.sender].lastEpoch == 0) {
            claimedMap[msg.sender].claimed = amount;
            claimedMap[msg.sender].lastEpoch = epoch;
        } else {
            claimedMap[msg.sender].claimed += amount;
            claimedMap[msg.sender].lastEpoch = epoch;
        }
    }

    function claim(uint256 epoch, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(0 < merkleProof.length, "MerkleDistributor: Invalid merkleProof");
        require(!isClaimed(epoch), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(epoch, amount);

        // Accumulate the total info
        totalClaimInfo.claimed = totalClaimInfo.claimed.add(amount);

        // transfer airdrop(btt) to msg.sender
        payable(msg.sender).transfer(amount);

        emit Claimed(epoch, index, msg.sender, amount);
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