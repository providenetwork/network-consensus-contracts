pragma solidity ^0.4.20;

import '../interfaces/INetworkStorage.sol';
import '../storage/AbstractStorage.sol';
import '../storage/EternalStorage.sol';


/*
Network storage contract.
*/
contract NetworkStorage is AbstractStorage, EternalStorage, INetworkStorage {

    function hashStorageKey(bytes32 _key) public view returns(bytes32) {
        return hashStorageKey(msg.sender, _key);
    }

    function hashStorageKey(address _namespace, bytes32 _key) internal pure returns(bytes32) {
        bytes memory addr = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            addr[i] = byte(uint8(uint(_namespace) / (2 ** (8 * (19 - i)))));
        }
        return keccak256(string(addr), _key);
    }

    function getAddress(bytes32 _key) public view returns(address) {
        return addressStorage[hashStorageKey(_key)];
    }
  
    function setAddress(bytes32 _key, address _addr) public {
        addressStorage[hashStorageKey(_key)] = _addr;
    }

    function getAddressArray(bytes32 _key) public view returns(address[]) {
        return addressArrayStorage[hashStorageKey(_key)];
    }

    function setAddressArray(bytes32 _key, address[] _addrs) public {
        addressArrayStorage[hashStorageKey(_key)] = _addrs;
    }

    function getAddressArrayLength(bytes32 _key) public view returns(uint256) {
        return addressArrayStorage[hashStorageKey(_key)].length;
    }

    function getAddressArrayItem(bytes32 _key, uint256 _index) public view returns(address) {
        return addressArrayStorage[hashStorageKey(_key)][_index];
    }

    function setAddressArrayItem(bytes32 _key, uint256 _index, address _addr) public {
        address[] storage addrArray = addressArrayStorage[hashStorageKey(_key)];
        if (_index == addrArray.length) {
            addrArray.push(_addr);
        } else {
            addrArray[_index] = _addr;
        }
    }

    function deleteAddressArrayItem(bytes32 _key, uint256 _index) public {
        address[] storage addrArray = addressArrayStorage[hashStorageKey(_key)];
        if (_index < addrArray.length) {
            delete addrArray[_index];
            if (_index == addrArray.length - 1) {
                addrArray.length = _index;
            }
        }
    }

    function getAddressToAddress(bytes32 _key, address _addr) public view returns(address) {
        return addressToAddressMappingStorage[hashStorageKey(_key)][_addr];
    }

    function setAddressToAddress(bytes32 _key, address _addr, address _val) public {
        addressToAddressMappingStorage[hashStorageKey(_key)][_addr] = _val;
    }

    function getAddressToAddressArray(bytes32 _key, address _addr) public view returns(address[]) {
        return addressToAddressArrayMappingStorage[hashStorageKey(_key)][_addr];
    }

    function setAddressToAddressArray(bytes32 _key, address _addr, address[] _addrs) public {
        addressToAddressArrayMappingStorage[hashStorageKey(_key)][_addr] = _addrs;
    }

    function getAddressToBool(bytes32 _key, address _addr) public view returns(bool) {
        return addressToBoolMappingStorage[hashStorageKey(_key)][_addr];
    }

    function setAddressToBool(bytes32 _key, address _addr, bool _val) public {
        addressToBoolMappingStorage[hashStorageKey(_key)][_addr] = _val;
    }

    function getAddressToUint(bytes32 _key, address _addr) public view returns(uint256) {
        return addressToUintMappingStorage[hashStorageKey(_key)][_addr];
    }

    function setAddressToUint(bytes32 _key, address _addr, uint256 _val) public {
        addressToUintMappingStorage[hashStorageKey(_key)][_addr] = _val;
    }

    function getAddressToUintArray(bytes32 _key, address _addr) public view returns(uint256[]) {
        return addressToUintArrayMappingStorage[hashStorageKey(_key)][_addr];
    }

    function setAddressToUintArray(bytes32 _key, address _addr, uint256[] _vals) public {
        addressToUintArrayMappingStorage[hashStorageKey(_key)][_addr] = _vals;
    }

    function getBool(bytes32 _key) public view returns(bool) {
        return boolStorage[hashStorageKey(_key)];
    }

    function setBool(bytes32 _key, bool val) public {
        boolStorage[hashStorageKey(_key)] = val;
    }

    function getUint(bytes32 _key) public view returns(uint256) {
        return uintStorage[hashStorageKey(_key)];
    }

    function setUint(bytes32 _key, uint256 val) public {
        uintStorage[hashStorageKey(_key)] = val;
    }
}
