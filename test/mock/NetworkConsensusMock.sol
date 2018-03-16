pragma solidity ^0.4.20;

import '../../contracts/network/NetworkConsensus.sol';


contract NetworkConsensusMock is NetworkConsensus {

    function NetworkConsensusMock(address _networkStorage, address _moc) 
        NetworkConsensus(_networkStorage, _moc) public
    {}

    function setKeyManagerMock(address _keyManager) public {
        networkStorage.setAddress("keyManager", _keyManager);
    }

    function setSystemAddress(address _systemAddress) public {
        networkStorage.setAddress("systemAddress", _systemAddress);
    }
}
