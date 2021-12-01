// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.5.8;
interface Token {
    function transfer(address dst, uint256 sad) external returns (bool);
    function balanceOf(address guy) external view returns (uint256);
}