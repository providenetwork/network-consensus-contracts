pragma solidity ^0.4.20;


interface INetworkConsensus {

    function addValidator(address, bool) public;
    function finalizeChange() public;
    function getMasterOfCeremony() public view returns(address);
    function getNetworkStorage() public view returns(address);
    function getPendingValidators() public view returns(address[]);
    function getSystemAddress() public view returns(address);
    function getValidators() public view returns(address[]);
    function getValidatorsCount() public view returns(uint256);
    function isValidator(address) public view returns(bool);
    function removeValidator(address, bool) public;
    function swapValidatorKey(address, address) public;
}
