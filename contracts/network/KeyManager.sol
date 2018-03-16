pragma solidity ^0.4.20;

import '../interfaces/INetworkConsensus.sol';
import './NetworkContract.sol';


/*
Key manager.
*/
contract KeyManager is NetworkContract {

    uint256 internal constant DEFAULT_MAX_INITIAL_VALIDATORS = 12;
    uint256 internal constant DEFAULT_MAX_TOTAL_VALIDATORS = 200;

    bytes32 internal constant INITIAL_KEY_COUNT_KEY = "initialKeyCount";
    bytes32 internal constant MAX_INITIAL_VALIDATORS_KEY = "maxInitialValidators";
    bytes32 internal constant MAX_TOTAL_VALIDATORS_KEY = "maxTotalValidators";
    bytes32 internal constant NETWORK_CONSENSUS_KEY = "networkConsensus";
    bytes32 internal constant PREVIOUS_KEY_MANAGER_KEY = "previousKeyManager";
    bytes32 internal constant VOTING_CONTRACT_KEY = "votingContract";

    enum InitialKeyState { Invalid, Activated, Deactivated }

    struct Keys {
        address payoutKey;
        address votingKey;
        bool isMiningActive;
        bool isPayoutActive;
        bool isVotingActive;
    }

    INetworkConsensus internal networkConsensus;

    event InitialKeyCreated(address indexed initialKey, uint256 time, uint256 initialKeysCount);
    event Migrated(string name, address key);
    event MiningKeyChanged(address key, string action);
    event PayoutKeyChanged(address key, address indexed miningKey, string action);
    event ValidatorInitialized(address indexed miningKey, address indexed payoutKey, address indexed votingKey);
    event VotingKeyChanged(address key, address indexed miningKey, string action);

    function KeyManager(address _networkConsensus, address _previousKeyManager) public {
        require(_networkConsensus != address(0));

        networkConsensus = INetworkConsensus(_networkConsensus);
        setNetworkStorage(networkConsensus.getNetworkStorage());

        networkStorage.setUint(MAX_INITIAL_VALIDATORS_KEY, DEFAULT_MAX_INITIAL_VALIDATORS);
        networkStorage.setUint(MAX_TOTAL_VALIDATORS_KEY, DEFAULT_MAX_TOTAL_VALIDATORS);

        address _masterOfCeremony = networkConsensus.getMasterOfCeremony();
        marshalValidatorKeys(_masterOfCeremony, address(0), address(0), true, false, false);
        networkStorage.setBool(getValidatorStorageKey(_masterOfCeremony, "successfulValidatorClone"), true);
        Migrated("miningKey", _masterOfCeremony);

        if (_previousKeyManager != address(0)) {
            networkStorage.setAddress(PREVIOUS_KEY_MANAGER_KEY, _previousKeyManager);
            KeyManager _previous = KeyManager(_previousKeyManager);
            networkStorage.setUint(INITIAL_KEY_COUNT_KEY, _previous.getInitialKeyCount());
        }
    }

    function addMiningKey(address _key) public onlyVotingContract withinTotalLimit {
        _addMiningKey(_key);
    }

    function addPayoutKey(address _key, address _miningKey) public onlyVotingContract {
        _addPayoutKey(_key, _miningKey);
    }

    function addVotingKey(address _key, address _miningKey) public onlyVotingContract {
        _addVotingKey(_key, _miningKey);
    }

    function createKeys(address _miningKey, address _payoutKey, address _votingKey) public onlyValidInitialKey {
        require(_miningKey != address(0) && _payoutKey != address(0) && _votingKey != address(0));
        require(_miningKey != _payoutKey && _miningKey != _votingKey && _payoutKey != _votingKey);
        require(_miningKey != msg.sender && _payoutKey != msg.sender && _votingKey != msg.sender);

        marshalValidatorKeys(_miningKey, _payoutKey, _votingKey, true, true, true);
        networkStorage.setAddress(getValidatorStorageKey(_votingKey, "miningKeyByVotingKey"), _miningKey);
        networkStorage.setAddress(getValidatorStorageKey(_miningKey, "votingKeyByMiningKey"), _votingKey);
        networkStorage.setUint(getValidatorStorageKey(msg.sender, "initialKeys"), uint8(InitialKeyState.Deactivated));

        networkConsensus.addValidator(_miningKey, true);
        ValidatorInitialized(_miningKey, _payoutKey, _votingKey);
    }

    function getInitialKey(address _initialKey) public view returns(uint8) {  // FIXME-- refactor as #getInitialKeyState
        return uint8(networkStorage.getUint(getValidatorStorageKey(_initialKey, "initialKeys")));
    }

    function getInitialKeyCount() public view returns(uint256) {
        return networkStorage.getUint(INITIAL_KEY_COUNT_KEY);
    }

    function getMaxInitialValidators() public view returns(uint256) {
        return networkStorage.getUint(MAX_INITIAL_VALIDATORS_KEY);
    }

    function getMaxTotalValidators() public view returns(uint256) {
        return networkStorage.getUint(MAX_TOTAL_VALIDATORS_KEY);
    }

    function getMiningKeyByVoting(address _votingKey) public view returns(address) {
        return networkStorage.getAddress(getValidatorStorageKey(_votingKey, "miningKeyByVotingKey"));
    }

    function getMiningKeyHistory(address _miningKey) public view returns(address) {
        return networkStorage.getAddress(getValidatorStorageKey(_miningKey, "miningKeyHistory"));
    }

    function getPayoutByMining(address _miningKey) public view returns(address) {
        return networkStorage.getAddress(getValidatorStorageKey(_miningKey, "payoutKeyByMiningKey"));
    }

    function getPreviousKeyManager() public view returns(address) {
        return networkStorage.getAddress(PREVIOUS_KEY_MANAGER_KEY);
    }

    function getVotingByMining(address _miningKey) public view returns(address) {
        return networkStorage.getAddress(getValidatorStorageKey(_miningKey, "votingKeyByMiningKey"));
    }

    function hasValidatorClone(address _miningKey) public view returns(bool) {
        return networkStorage.getBool(getValidatorStorageKey(_miningKey, "successfulValidatorClone"));
    }

    function initiateKeys(address _initialKey) public {
        require(msg.sender == networkConsensus.getMasterOfCeremony());
        require(_initialKey != address(0));
        require(getInitialKey(_initialKey) == uint8(InitialKeyState.Invalid));
        require(_initialKey != networkConsensus.getMasterOfCeremony());
        require(networkStorage.getUint(INITIAL_KEY_COUNT_KEY) < networkStorage.getUint(MAX_INITIAL_VALIDATORS_KEY));

        networkStorage.setUint(getValidatorStorageKey(_initialKey, "initialKeys"), uint8(InitialKeyState.Activated));
        networkStorage.setUint(INITIAL_KEY_COUNT_KEY, networkStorage.getUint(INITIAL_KEY_COUNT_KEY) + 1);
        InitialKeyCreated(_initialKey, getTime(), networkStorage.getUint(INITIAL_KEY_COUNT_KEY));
    }

    function isMiningActive(address _miningKey) public view returns(bool) {
        return unmarshalValidatorKeys(_miningKey).isMiningActive;
    }

    function isPayoutActive(address _miningKey) public view returns(bool) {
        return unmarshalValidatorKeys(_miningKey).isPayoutActive;
    }

    function isVotingActive(address _votingKey) public view returns(bool) {
        address _miningKey = getMiningKeyByVoting(_votingKey);
        return unmarshalValidatorKeys(_miningKey).isVotingActive;
    }

    function migrateInitialKey(address _initialKey) public {
        KeyManager previous = KeyManager(networkStorage.getAddress(PREVIOUS_KEY_MANAGER_KEY));
        require(getInitialKey(_initialKey) == 0);
        require(_initialKey != address(0));
        uint8 status = previous.getInitialKey(_initialKey);
        require(status == uint8(InitialKeyState.Activated) || status == uint8(InitialKeyState.Deactivated));
        networkStorage.setUint(getValidatorStorageKey(_initialKey, "initialKeys"), status);
        Migrated("initialKey", _initialKey);
    }

    function migrateMiningKey(address _miningKey) public {
        KeyManager previous = KeyManager(networkStorage.getAddress(PREVIOUS_KEY_MANAGER_KEY));
        require(_miningKey != address(0));
        require(previous.isMiningActive(_miningKey));
        require(!isMiningActive(_miningKey));
        require(!hasValidatorClone(_miningKey));
        address payoutKey = previous.getPayoutByMining(_miningKey);
        address votingKey = previous.getVotingByMining(_miningKey);
        marshalValidatorKeys(_miningKey, payoutKey, votingKey, previous.isMiningActive(_miningKey), previous.isPayoutActive(_miningKey), previous.isVotingActive(votingKey));
        networkStorage.setAddress(getValidatorStorageKey(previous.getVotingByMining(_miningKey), "miningKeyByVotingKey"), _miningKey);
        networkStorage.setBool(getValidatorStorageKey(_miningKey, "successfulValidatorClone"), true);
        Migrated("miningKey", _miningKey);
    }

    function removeMiningKey(address _key) public onlyVotingContract {
        _removeMiningKey(_key);
    }

    function removePayoutKey(address _miningKey) public onlyVotingContract {
        _removePayoutKey(_miningKey);
    }

    function removeVotingKey(address _miningKey) public onlyVotingContract {
        _removeVotingKey(_miningKey);
    }

    function swapMiningKey(address _key, address _oldMiningKey) public onlyVotingContract {
        networkStorage.setAddress(getValidatorStorageKey(_key, "miningKeyHistory"), _oldMiningKey);
        address payoutKey = getPayoutByMining(_oldMiningKey);
        address votingKey = getVotingByMining(_oldMiningKey);
        require(isMiningActive(_oldMiningKey));
        marshalValidatorKeys(_key, payoutKey, votingKey, true, isPayoutActive(_oldMiningKey), isVotingActive(votingKey));
        networkConsensus.swapValidatorKey(_key, _oldMiningKey);
        marshalValidatorKeys(_oldMiningKey, address(0), address(0), false, false, false);
        networkStorage.setAddress(getValidatorStorageKey(votingKey, "miningKeyByVotingKey"), _key);
        networkStorage.setAddress(getValidatorStorageKey(_key, "votingKeyByMiningKey"), votingKey);
        MiningKeyChanged(_key, "swapped");
    }

    function swapPayoutKey(address _key, address _miningKey) public onlyVotingContract {
        _swapPayoutKey(_key, _miningKey);
    }

    function swapVotingKey(address _key, address _miningKey) public onlyVotingContract {
        _swapVotingKey(_key, _miningKey);
    }

    function _swapPayoutKey(address _key, address _miningKey) private {
        _removePayoutKey(_miningKey);
        _addPayoutKey(_key, _miningKey);
    }

    function _swapVotingKey(address _key, address _miningKey) private {
        _removeVotingKey(_miningKey);
        _addVotingKey(_key, _miningKey);
    }

    function _addMiningKey(address _key) private {
        marshalValidatorKeys(_key, address(0), address(0), true, false, false);
        networkConsensus.addValidator(_key, true);
        MiningKeyChanged(_key, "added");
    }

    function _addPayoutKey(address _key, address _miningKey) private {
        Keys memory keys = unmarshalValidatorKeys(_miningKey);
        require(keys.isMiningActive && _key != _miningKey);
        if (keys.isPayoutActive && keys.payoutKey != address(0)) {
            _swapPayoutKey(_key, _miningKey);
        } else {
            keys.payoutKey = _key;
            keys.isPayoutActive = true;
            marshalValidatorKeys(_miningKey, keys.payoutKey, keys.votingKey, keys.isMiningActive, keys.isPayoutActive, keys.isVotingActive);
            PayoutKeyChanged(_key, _miningKey, "added");
        }
    }

    function _addVotingKey(address _key, address _miningKey) private {
        Keys memory keys = unmarshalValidatorKeys(_miningKey);
        require(keys.isMiningActive && _key != _miningKey);
        if (keys.isVotingActive && keys.votingKey != address(0)) {
            _swapVotingKey(_key, _miningKey);
        } else {
            keys.votingKey = _key;
            keys.isVotingActive = true;
            marshalValidatorKeys(_miningKey, keys.payoutKey, keys.votingKey, keys.isMiningActive, keys.isPayoutActive, keys.isVotingActive);
            networkStorage.setAddress(getValidatorStorageKey(_key, "miningKeyByVotingKey"), _miningKey);
            networkStorage.setAddress(getValidatorStorageKey(_miningKey, "votingKeyByMiningKey"), _key);
            VotingKeyChanged(_key, _miningKey, "added");
        }
    }

    function _removeMiningKey(address _key) private {
        Keys memory keys = unmarshalValidatorKeys(_key);
        require(keys.isMiningActive);
        networkStorage.setAddress(getValidatorStorageKey(_key, "miningKeyByVotingKey"), address(0));
        networkStorage.setAddress(getValidatorStorageKey(_key, "votingKeyByMiningKey"), address(0));
        marshalValidatorKeys(_key, address(0), address(0), false, false, false);
        networkConsensus.removeValidator(_key, true);
        MiningKeyChanged(_key, "removed");       
    }

    function _removePayoutKey(address _miningKey) private {
        Keys memory keys = unmarshalValidatorKeys(_miningKey);
        require(keys.isPayoutActive);
        address oldPayout = keys.payoutKey;
        keys.payoutKey = address(0);
        keys.isPayoutActive = false;
        marshalValidatorKeys(_miningKey, keys.payoutKey, keys.votingKey, keys.isMiningActive, keys.isPayoutActive, keys.isVotingActive);
        PayoutKeyChanged(oldPayout, _miningKey, "removed");
    }

    function _removeVotingKey(address _miningKey) private {
        Keys memory keys = unmarshalValidatorKeys(_miningKey);
        require(keys.isVotingActive);
        address oldVoting = keys.votingKey;
        keys.votingKey = address(0);
        keys.isVotingActive = false;
        marshalValidatorKeys(_miningKey, keys.payoutKey, keys.votingKey, keys.isMiningActive, keys.isPayoutActive, keys.isVotingActive);
        networkStorage.setAddress(getValidatorStorageKey(oldVoting, "miningKeyByVotingKey"), address(0));
        networkStorage.setAddress(getValidatorStorageKey(_miningKey, "votingKeyByMiningKey"), address(0));
        VotingKeyChanged(oldVoting, _miningKey, "removed");
    }

    function marshalValidatorKeys(address _addr, address _payoutKey, address _votingKey, bool _isMiningActive, bool _isPayoutActive, bool _isVotingActive) internal {
        networkStorage.setAddress(getValidatorStorageKey(_addr, "payoutKey"), _payoutKey);
        networkStorage.setAddress(getValidatorStorageKey(_addr, "votingKey"), _votingKey);
        networkStorage.setBool(getValidatorStorageKey(_addr, "isMiningActive"), _isMiningActive);
        networkStorage.setBool(getValidatorStorageKey(_addr, "isPayoutActive"), _isPayoutActive);
        networkStorage.setBool(getValidatorStorageKey(_addr, "isVotingActive"), _isVotingActive);
    }

    function unmarshalValidatorKeys(address _addr) internal view returns(Keys memory) {
        return Keys({
            payoutKey: networkStorage.getAddress(getValidatorStorageKey(_addr, "payoutKey")),
            votingKey: networkStorage.getAddress(getValidatorStorageKey(_addr, "votingKey")),
            isMiningActive: networkStorage.getBool(getValidatorStorageKey(_addr, "isMiningActive")),
            isPayoutActive: networkStorage.getBool(getValidatorStorageKey(_addr, "isPayoutActive")),
            isVotingActive: networkStorage.getBool(getValidatorStorageKey(_addr, "isVotingActive"))
        });
    }

    modifier onlyValidInitialKey {
        require(getInitialKey(msg.sender) == uint8(InitialKeyState.Activated));
        _;
    }

    modifier onlyVotingContract {
        //require(msg.sender == networkStorage.getAddress(VOTING_CONTRACT_KEY));
        _;
    }

    modifier withinTotalLimit {
        require(networkConsensus.getValidatorsCount() <= networkStorage.getUint(MAX_TOTAL_VALIDATORS_KEY));
        _;
    }
}
