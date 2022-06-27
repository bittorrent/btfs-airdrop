// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsStatus {
    using SafeMath for uint256;

    // info
    struct info {
        uint256 createTime;
        bytes16 version;
        uint256 num;
        uint8[] hearts;
        uint256 lastNum;
        uint256 lastTime;
    }
    // which peer, last info
    mapping(string => info) private peerMap;

    // address singnedAddress = "0x4b1d4f6ffcd4aafec6c05e7844f0f0b07985f4ca";
    address singnedAddress;

    //version
    bytes16 public currentVersion;

    event versionChanged(bytes16 currentVersion, bytes16 version);
    event statusReported(string peer, uint256 createTime, bytes16 version, uint256 num, uint256 nowTime, uint8[] hearts);

    //stat
    struct statistics {
        uint64 total;
        uint64 totalUsers;
    }
    statistics  public totalStat;


    // owner
    address public owner;
    constructor() {
        owner = msg.sender;
    }


    // set current version
    // only owner do it
    function setCurrentVersion(bytes16 ver) external {
        bytes16 lastVersion = currentVersion;

        currentVersion = ver;
        emit versionChanged(lastVersion, currentVersion);
    }


    function setHeart(string memory peer, uint256 num, uint256 nowTime) internal {
        uint256 diffTime = nowTime - peerMap[peer].lastTime;
        if (diffTime > 30 * 86400) {
            diffTime = 30 * 86400;
        }

        uint256 diffNum = num - peerMap[peer].lastNum;
        if (diffNum > 30) {
            diffNum = 30;
        }

        uint times = diffTime/86400;
        uint256 balance = diffNum;
        for (uint256 i = 1; i < times; i++) {
            uint indexTmp = (nowTime-i*86400)%86400%30;
            peerMap[peer].hearts[indexTmp] = uint8(diffNum/times);

            balance = balance - diffNum/times;
        }

        uint index = nowTime%86400%30;
        peerMap[peer].hearts[index] = uint8(balance);
    }

    function reportStatus(string memory peer, uint256 createTime, bytes16 version, uint256 num, uint256 nowTime, bytes memory signed) external {
        require(0 < createTime, "reportStatus: Invalid createTime");
        require(0 < version.length, "reportStatus: Invalid version.length");
        require(0 < num, "reportStatus: Invalid num");
        require(0 < signed.length, "reportStatus: Invalid signed");

        require(peerMap[peer].lastNum <= num, "reportStatus: Invalid lastNum<num");

        // Verify the signed with msg.sender.
        bytes32 hash = keccak256(abi.encodePacked(peer, createTime, version, num, nowTime));
        require(verify(hash, signed), "reportStatus: Invalid signed address.");

        uint index = nowTime%86400%30;
        peerMap[peer].createTime = createTime;
        peerMap[peer].version = version;
        peerMap[peer].lastNum = num;

        if (peerMap[peer].num == 0) {
            if (num > 24) {
                num = 24;
            }
            peerMap[peer].hearts[index] = uint8(num);
            totalStat.totalUsers += 1;
        } else {
            setHeart(peer, num, nowTime);
        }

        // set total
        totalStat.total += 1;

        emit statusReported(
            peer,
            createTime,
            version,
            num,
            nowTime,
            peerMap[peer].hearts
        );
    }

    function verify(bytes32 hash, bytes memory signed) internal view returns (bool) {
        return recoverSigner(hash, signed);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
    internal
    view
    returns (bool)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s) == address(singnedAddress);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        uint8,
        bytes32,
        bytes32
    )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}