pragma solidity ^0.4.20;

import '../interfaces/INetworkStorage.sol';
import './NetworkStorage.sol';


/*
Network base contract.
*/
contract NetworkContract {

    INetworkStorage internal networkStorage;

    function NetworkContract() public {}

    function getTime() public view returns(uint256) {
        return now;
    }

    function getValidatorStorageKey(address _addr, bytes _path) internal pure returns(bytes32) {
        bytes memory key = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            key[i] = byte(uint8(uint(_addr) / (2 ** (8 * (19 - i)))));
        }
        return keccak256(string(key), string(_path));
    }

    function hashStorageKey(bytes32 key) public view returns(bytes32) {
        return networkStorage.hashStorageKey(key);
    }

    function setNetworkStorage(address _absStorage) internal {
        require(networkStorage == address(0));
        require(_absStorage != address(0));
        networkStorage = INetworkStorage(_absStorage);
    }
}
