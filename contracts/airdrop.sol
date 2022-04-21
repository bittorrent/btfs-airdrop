// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// Open Zeppelin libraries for controlling upgradability and access.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsAirdrop is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    bytes32 public merkleRoot;
    bytes32 public pendingMerkleRoot;
    uint256 public lastTime;

    // admin address which can propose adding a new merkle root
    address public proposalAuthority;
    // admin address which approves or rejects a proposed merkle root
    address public reviewAuthority;
    // admin address which can withdraw all contract balance
    address public superAuthority;

    struct statistics {
        uint256 total;
        uint256 claimed;
    }

    statistics  public totalInfo;

    struct claimedUser {
        bytes32 lastMerkleRoot;
        uint256 claimed;
    }

    mapping(address => claimedUser) private claimedUserMap;

    event Claimed(bytes32 merkleRootInput, uint256 index, address account, uint256 amount);
    event SetTotalAmount(bytes32 merkleRoot, uint256 amount);
    event WithdrawAllBalance(address account, uint256 amount);

    // initialize
    function initialize(address _proposalAuthority, address _reviewAuthority, address _superAuthor) public initializer {
        proposalAuthority = _proposalAuthority;
        reviewAuthority = _reviewAuthority;
        superAuthority = _superAuthor;
        __Ownable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // receive()
    receive() external payable {}


    function setProposalAuthority(address _account) public {
        require(msg.sender == proposalAuthority, "you can not set proposal authority.");
        proposalAuthority = _account;
    }

    function setReviewAuthority(address _account) public {
        require(msg.sender == reviewAuthority, "you can not set review authority.");
        reviewAuthority = _account;
    }

    function setSuperAuthority(address _account) public {
        require(msg.sender == superAuthority, "you can not set super authority.");
        superAuthority = _account;
    }

    // super authority withdraw all balance.
    function withdrawAllBalance() external {
        require(msg.sender == superAuthority, "withdrawAmount: you are not super authority.");
        payable(msg.sender).transfer(address(this).balance);

        emit WithdrawAllBalance(msg.sender, address(this).balance);
    }


    // every day, the proposal authority calls to submit the merkle root for a new airdrop.
    function proposeMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == proposalAuthority, "msg.sender != proposalAuthority");
        require(pendingMerkleRoot == 0x00, "pendingMerkleRoot != 0x00");
        require(_merkleRoot != merkleRoot, "proposeMerkleRoot: merkleRoot is already used.");
        //require(block.timestamp >= lastRoot + 86400, "proposeMerkleRoot: it takes 1 day to modify it.");
        pendingMerkleRoot = _merkleRoot;
    }

    // After validating the correctness of the pending merkle root, the reviewing authority
    // calls to confirm it and the distribution may begin.
    function reviewPendingMerkleRoot(bool _approved) public {
        require(msg.sender == reviewAuthority, "msg.sender != reviewAuthority");
        require(pendingMerkleRoot != 0x00, "pendingMerkleRoot != 0x00");
        if (_approved) {
            merkleRoot = pendingMerkleRoot;

            lastTime = block.timestamp / 86400 * 86400;
        }
        delete pendingMerkleRoot;
    }

    // set the total amount of airdrop this period
    function setTotalAmount(uint256 totalAmount) public onlyOwner {
        require(totalAmount > totalInfo.total, "totalAmount is less than totalInfo.total");
        totalInfo.total = totalAmount;

        emit SetTotalAmount(merkleRoot, totalAmount);
    }


    function getTotalClaimInfo() view external returns (uint256 total, uint256 claimed, bytes32 curMerkleRoot) {
        total = totalInfo.total;
        claimed = totalInfo.claimed;
        curMerkleRoot = merkleRoot;
    }

    function getUserClaimed() view external returns (uint256 userClaimed, bytes32 lastMerkleRoot) {
        userClaimed = claimedUserMap[msg.sender].claimed;
        lastMerkleRoot = claimedUserMap[msg.sender].lastMerkleRoot;
    }

    function isUserClaimed(bytes32 merkleRootInput) public view returns (bool) {
        if (claimedUserMap[msg.sender].lastMerkleRoot == 0x00) {
            return false;
        }
        if (claimedUserMap[msg.sender].lastMerkleRoot == merkleRootInput) {
            return true;
        }

        return false;
    }

    function _setTotalClaimed(uint256 transferAmount) private {
        totalInfo.claimed = totalInfo.claimed.add(transferAmount);
    }

    function _setUserClaimed(uint256 amount) private {
        claimedUserMap[msg.sender].claimed = amount;
        claimedUserMap[msg.sender].lastMerkleRoot = merkleRoot;
    }

    function _getUserTransferAmount(uint256 amount) private view returns (uint256) {
        return amount.sub(claimedUserMap[msg.sender].claimed);
    }

    function claim(bytes32 merkleRoot2, uint256 index2, uint256 amount2, bytes32[] calldata merkleProof2,
        bytes32 merkleRoot1, uint256 index1, uint256 amount1, bytes32[] calldata merkleProof1) external {
        require(0 < merkleProof1.length, "claim: Invalid merkleProof1");
        require(merkleRoot2 == merkleRoot, "claim: Invalid merkleRoot2");
        require(!isUserClaimed(merkleRoot2), "claim: Drop already claimed.");

        // Verify the merkle proof1 with msg.sender.
        bytes32 node1 = keccak256(abi.encodePacked(index1, msg.sender, amount1));
        require(verify(merkleProof1, merkleRoot1, node1), "claim: Invalid proof1.");

        // Verify the merkle proof with merkleRoot1.
        bytes32 node2 = keccak256(abi.encodePacked(index2, merkleRoot1, amount2));
        require(verify(merkleProof2, merkleRoot, node2), "claim: Invalid proof2.");

        // get transfer amount
        uint256 transferAmount = _getUserTransferAmount(amount1);

        // transfer to msg.sender
        payable(msg.sender).transfer(transferAmount);

        // set claimed amount
        _setTotalClaimed(transferAmount);
        _setUserClaimed(amount1);

        emit Claimed(merkleRoot2, index1, msg.sender, transferAmount);
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