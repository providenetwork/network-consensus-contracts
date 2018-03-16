pragma solidity ^0.4.20;


interface INetworkStorage {

    function hashStorageKey(bytes32 key) public view returns(bytes32);

    function getAddress(bytes32 _key) public view returns(address);
    function setAddress(bytes32 _key, address _addr) public;

    function getAddressArray(bytes32 _key) public view returns(address[]);
    function setAddressArray(bytes32 _key, address[] _addrs) public;
    function getAddressArrayLength(bytes32 _key) public view returns(uint256);

    function getAddressArrayItem(bytes32 _key, uint256 _index) public view returns(address);
    function setAddressArrayItem(bytes32 _key, uint256 _index, address _addr) public;
    function deleteAddressArrayItem(bytes32 _key, uint256 _index) public;

    function getAddressToAddress(bytes32 _key, address _addr) public view returns(address);
    function setAddressToAddress(bytes32 _key, address _addr, address _val) public;

    function getAddressToAddressArray(bytes32 _key, address _addr) public view returns(address[]);
    function setAddressToAddressArray(bytes32 _key, address _addr, address[] _addrs) public;

    function getAddressToBool(bytes32 _key, address _addr) public view returns(bool);
    function setAddressToBool(bytes32 _key, address _addr, bool _val) public;

    function getAddressToUint(bytes32 _key, address _addr) public view returns(uint256);
    function setAddressToUint(bytes32 _key, address _addr, uint256 _val) public;

    function getAddressToUintArray(bytes32 _key, address _addr) public view returns(uint256[]);
    function setAddressToUintArray(bytes32 _key, address _addr, uint256[] _vals) public;

    function getBool(bytes32 _key) public view returns(bool);
    function setBool(bytes32 _key, bool _val) public;

    function getUint(bytes32 _key) public view returns(uint256);
    function setUint(bytes32 _key, uint256 _val) public;
}
