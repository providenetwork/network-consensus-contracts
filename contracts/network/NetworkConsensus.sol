pragma solidity ^0.4.20;

import '../interfaces/INetworkConsensus.sol';
import './NetworkContract.sol';
import './NetworkStorage.sol';


/*
Network consensus.

See https://wiki.parity.io/Aura
*/
contract NetworkConsensus is NetworkContract, INetworkConsensus {

    address internal constant DEFAULT_SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    bytes32 internal constant CURRENT_VALIDATORS_KEY = "currentValidators";
    bytes32 internal constant CURRENT_VALIDATORS_LENGTH_KEY = "currentValidatorsLength";
    bytes32 internal constant FINALIZED_KEY = "finalized";
    bytes32 internal constant KEY_MANAGER_KEY = "keyManager";
    bytes32 internal constant MASTER_OF_CEREMONY_KEY = "masterOfCeremony";
    bytes32 internal constant MASTER_OF_CEREMONY_INITIALIZED_KEY = "masterOfCeremonyInitialized";
    bytes32 internal constant MAX_VALIDATORS_KEY = "maxValidators";
    bytes32 internal constant PENDING_VALIDATORS_KEY = "pendingValidators";
    bytes32 internal constant PENDING_VALIDATORS_LENGTH_KEY = "pendingValidatorsLength";
    bytes32 internal constant REGISTRY_KEY = "pendingValidators";
    bytes32 internal constant SYSTEM_ADDRESS_KEY = "systemAddress";

    struct ValidatorMeta {
        bool isValidator;
        uint256 index;
    }

    event ChangeFinalized(address[] newSet);
    event InitiateChange(bytes32 indexed parentHash, address[] newSet);  // see https://wiki.parity.io/Validator-Set.html

    function NetworkConsensus(address _networkStorage, address _masterOfCeremony) public {
        require(_networkStorage != address(0));
        require(_masterOfCeremony != address(0));

        setNetworkStorage(_networkStorage);
        networkStorage.setAddress(SYSTEM_ADDRESS_KEY, DEFAULT_SYSTEM_ADDRESS);

        initMasterOfCeremony(_masterOfCeremony);
    }

    function initMasterOfCeremony(address _masterOfCeremony) internal {
        networkStorage.setAddress(MASTER_OF_CEREMONY_KEY, _masterOfCeremony);
        networkStorage.setBool(MASTER_OF_CEREMONY_INITIALIZED_KEY, true);

        marshalValidatorMeta(_masterOfCeremony, true, 0);

        networkStorage.setAddressArrayItem(PENDING_VALIDATORS_KEY, 0, _masterOfCeremony);
        networkStorage.setUint(PENDING_VALIDATORS_LENGTH_KEY, 1);
        networkStorage.setBool(FINALIZED_KEY, false);
    }

    function _currentValidators() internal view returns(address[] memory) {
        uint256 currentValidatorsCount = networkStorage.getUint(CURRENT_VALIDATORS_LENGTH_KEY);
        address[] memory currentValidators = new address[](currentValidatorsCount);
        for (uint256 i = 0; i < currentValidatorsCount; i++) {
            currentValidators[i] = networkStorage.getAddressArrayItem(CURRENT_VALIDATORS_KEY, i);
        }
        return currentValidators;
    }

    function _pendingValidators() internal view returns(address[] memory) {
        uint256 pendingValidatorCount = networkStorage.getUint(PENDING_VALIDATORS_LENGTH_KEY);
        address[] memory pendingValidators = new address[](pendingValidatorCount);
        for (uint256 i = 0; i < pendingValidatorCount; i++) {
            pendingValidators[i] = networkStorage.getAddressArrayItem(PENDING_VALIDATORS_KEY, i);
        }
        return pendingValidators;
    }

    /// Called when an initiated change reaches finality and is activated. 
    /// Only valid when msg.sender == SUPER_USER (EIP96, 2**160 - 2)
    ///
    /// Also called when the contract is first enabled for consensus. In this case,
    /// the "change" finalized is the activation of the initial set.
    function finalizeChange() public onlySystem notFinalized {
        address[] memory currentValidators = _pendingValidators();
        networkStorage.setAddressArray(CURRENT_VALIDATORS_KEY, currentValidators);
        networkStorage.setUint(CURRENT_VALIDATORS_LENGTH_KEY, currentValidators.length);
        networkStorage.setBool(FINALIZED_KEY, true);
        ChangeFinalized(currentValidators);
    }

    function addValidator(address _validator, bool _shouldFireEvent) public onlyKeyManager isNewValidator(_validator) {
        require(_validator != address(0));
        networkStorage.setBool(FINALIZED_KEY, false);
        uint256 idx = _pendingValidators().length;
        networkStorage.setAddressArrayItem(PENDING_VALIDATORS_KEY, idx, _validator);
        networkStorage.setUint(PENDING_VALIDATORS_LENGTH_KEY, idx + 1);
        address[] memory pendingValidators = _pendingValidators();
        marshalValidatorMeta(_validator, true, pendingValidators.length);
        if (_shouldFireEvent) {
            InitiateChange(block.blockhash(block.number - 1), _pendingValidators());
        }
    }

    function removeValidator(address _validator, bool _shouldFireEvent) public onlyKeyManager isNotNewValidator(_validator) {
        uint256 removedIndex = unmarshalValidatorMeta(_validator).index;
        address[] memory pendingValidators = _pendingValidators();
        uint256 lastIndex = pendingValidators.length - 1;
        address lastValidator = pendingValidators[lastIndex];  // Can not remove the last validator.
        networkStorage.setAddressArrayItem(PENDING_VALIDATORS_KEY, removedIndex, lastValidator); // Override the removed validator with the last one.
        marshalValidatorMeta(lastValidator, true, removedIndex);  // Update the index of the last validator.
        networkStorage.deleteAddressArrayItem(PENDING_VALIDATORS_KEY, lastIndex);
        pendingValidators = _pendingValidators();
        require(pendingValidators.length > 0);
        networkStorage.deleteAddressArrayItem(PENDING_VALIDATORS_KEY, pendingValidators.length - 1);
        networkStorage.setUint(PENDING_VALIDATORS_LENGTH_KEY, pendingValidators.length - 1);
        marshalValidatorMeta(_validator, false, 0);
        networkStorage.setBool(FINALIZED_KEY, false);
        if (_shouldFireEvent) {
            InitiateChange(block.blockhash(block.number - 1), _pendingValidators());
        }
    }

    function swapValidatorKey(address _newKey, address _oldKey) public onlyKeyManager {
        require(isValidator(_oldKey));
        removeValidator(_oldKey, false);
        addValidator(_newKey, false);
        InitiateChange(block.blockhash(block.number - 1), _pendingValidators());
    }

    function finalized() public view returns(bool) {
        return networkStorage.getBool(FINALIZED_KEY);
    }

    function getMasterOfCeremony() public view returns(address) {
        return networkStorage.getAddress(MASTER_OF_CEREMONY_KEY);
    }

    function getNetworkStorage() public view returns(address) {
        return networkStorage;
    }

    function getSystemAddress() public view returns(address) {
        return networkStorage.getAddress(SYSTEM_ADDRESS_KEY);
    }

    function getPendingValidators() public view returns(address[]) {
        return _pendingValidators();
    }

    function getValidatorsCount() public view returns(uint256) {
        return networkStorage.getAddressArrayLength(CURRENT_VALIDATORS_KEY);
    }

    function getValidators() public view returns(address[]) {
        return _currentValidators();
    }

    function isValidator(address _addr) public view returns(bool) {
        return unmarshalValidatorMeta(_addr).isValidator;
    }

    function initKeyManager(address _addr) public onlyWithoutKeyManager {
        require(msg.sender == getMasterOfCeremony());
        networkStorage.setAddress(KEY_MANAGER_KEY, _addr);
    }

    function getValidatorStorageKey(address _addr, bytes _path) internal pure returns(bytes32) {
        bytes memory key = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            key[i] = byte(uint8(uint(_addr) / (2 ** (8 * (19 - i)))));
        }
        return keccak256(string(key), string(_path));
    }

    function marshalValidatorMeta(address _addr, bool _isValidator, uint256 _index) internal {
        networkStorage.setBool(getValidatorStorageKey(_addr, "isValidator"), _isValidator);
        networkStorage.setUint(getValidatorStorageKey(_addr, "index"), _index);
    }

    function unmarshalValidatorMeta(address _addr) internal view returns(ValidatorMeta memory) {
        return ValidatorMeta({
            isValidator: networkStorage.getBool(getValidatorStorageKey(_addr, "isValidator")),
            index: networkStorage.getUint(getValidatorStorageKey(_addr, "index"))
        });
    }

    modifier isNewValidator(address _addr) {
        require(!isValidator(_addr));
        _;
    }

    modifier isNotNewValidator(address _addr) {
        require(isValidator(_addr));
        _;
    }

    modifier notFinalized {
        require(!finalized());
        _;
    }

    modifier onlyKeyManager {
        require(msg.sender == networkStorage.getAddress(KEY_MANAGER_KEY));
        _;
    }

    modifier onlySystem {
        require(msg.sender == networkStorage.getAddress(SYSTEM_ADDRESS_KEY));
        _;
    }

    modifier onlyWithoutKeyManager {
        require(networkStorage.getAddress(KEY_MANAGER_KEY) == address(0));
        _;
    }
}
