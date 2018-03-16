pragma solidity ^0.4.20;


/*
Eternal storage
*/
contract EternalStorage {

    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => uint256) internal uintStorage;
    
    mapping(bytes32 => mapping(address => address)) internal addressToAddressMappingStorage;
    mapping(bytes32 => mapping(address => address[])) internal addressToAddressArrayMappingStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolMappingStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUintMappingStorage;
    mapping(bytes32 => mapping(address => uint256[])) internal addressToUintArrayMappingStorage;
}
