
pragma solidity 0.5.8;

interface Distributor {
    function sendAirdrop(address _receiver, uint256 _amount) external returns(bool);
}