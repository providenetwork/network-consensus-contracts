pragma solidity ^0.4.23;

import './lib/auth_os.sol';

/*
Network consensus.

See https://wiki.parity.io/Aura
*/
contract NetworkConsensus {

    bytes4 internal constant DEFAULT_INIT = bytes4(keccak256("init()"));
    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    // Default app constants

    bytes32 internal constant DEFAULT_CONSENSUS_APP_NAME = "Aura";
    bytes internal constant DEFAULT_CONSENSUS_APP_DESC = "Proof-of-authority consensus protocol implementing the authority round consensus algorithm";
    bytes32 internal constant DEFAULT_CONSENSUS_APP_VERSION = "0.0.1";
    bytes internal constant DEFAULT_CONSENSUS_APP_VERSION_DESC = "Alpha authority round consensus";
    bytes4 internal constant DEFAULT_CONSENSUS_APP_INIT_SEL = bytes4(keccak256("init(address,address,address)"));
    bytes internal constant DEFAULT_CONSENSUS_APP_INIT_DESC = "Default initializer";

    // App selectors

    bytes4 internal constant GET_MAX_VALIDATOR_COUNT_SEL = bytes4(keccak256("getMaximumValidatorCount(address,bytes32)"));
    bytes4 internal constant GET_MIN_VALIDATOR_COUNT_SEL = bytes4(keccak256("getMinimumValidatorCount(address,bytes32)"));
    bytes4 internal constant GET_VALIDATOR_SEL = bytes4(keccak256("getValidator(address,bytes32,address)"));
    bytes4 internal constant GET_VALIDATOR_INDEX_SEL = bytes4(keccak256("getValidatorIndex(address,bytes32,address)"));
    bytes4 internal constant GET_VALIDATORS_SEL = bytes4(keccak256("getValidators(address,bytes32)"));
    bytes4 internal constant GET_VALIDATOR_COUNT_SEL = bytes4(keccak256("getValidatorCount(address,bytes32)"));
    bytes4 internal constant GET_VALIDATOR_CONSOLE_SEL = bytes4(keccak256("getValidatorConsole(address,bytes32)"));
    bytes4 internal constant GET_VALIDATOR_METADATA_SEL = bytes4(keccak256("getValidatorMetadata(address,bytes32,address)"));
    bytes4 internal constant GET_VALIDATOR_SUPPORT_COUNT_SEL = bytes4(keccak256("getValidatorSupportCount(address,bytes32,address)"));
    bytes4 internal constant GET_VALIDATOR_SUPPORT_DIVISOR_SEL = bytes4(keccak256("getValidatorSupportDivisor(address,bytes32)"));
    bytes4 internal constant GET_VOTING_CONSOLE_SEL = bytes4(keccak256("getVotingConsole(address,bytes32)"));
    bytes4 internal constant GET_PENDING_VALIDATORS_SEL = bytes4(keccak256("getPendingValidators(address,bytes32)"));
    bytes4 internal constant GET_PENDING_VALIDATOR_COUNT_SEL = bytes4(keccak256("getPendingValidatorCount(address,bytes32)"));
    bytes4 internal constant GET_ACTIVE_BALLOTS_SEL = bytes4(keccak256("getActiveBallots(address,bytes32)"));  
    bytes4 internal constant GET_BALLOTS_SEL = bytes4(keccak256("getBallots(address,bytes32)"));
    bytes4 internal constant GET_FINALIZED_SEL = bytes4(keccak256("getFinalized(address,bytes32)"));

    bytes4 internal constant ADD_ARBITRARY_PROPOSAL_SEL = bytes4(keccak256("addArbitraryProposal(address,uint,uint,uint,bytes,bytes,bytes)"));
    bytes4 internal constant ADD_PROPOSAL_SEL = bytes4(keccak256("addProposal(address,uint,uint,uint,bytes,bytes,bytes32[])"));
    bytes4 internal constant ADD_VALIDATOR_SEL = bytes4(keccak256("addValidator(address,uint)"));
    bytes4 internal constant FINALIZE_CHANGE_SEL = bytes4(keccak256("finalizeChange()"));
    bytes4 internal constant FINALIZE_CONSENSUS_VERSION_SEL = bytes4(keccak256("finalizeConsensusVersion(bytes32,bytes32,address,bytes4,bytes,bytes)"));
    bytes4 internal constant REMOVE_VALIDATOR_SEL = bytes4(keccak256("removeValidator(address)"));
    bytes4 internal constant REPORT_BENIGN_SEL = bytes4(keccak256("report(address,uint,bool,bytes)"));
    bytes4 internal constant REPORT_MALICIOUS_SEL = bytes4(keccak256("report(address,uint,bool,bytes)"));
    bytes4 internal constant SET_FINALIZED_SEL = bytes4(keccak256("setFinalized(bool)"));
    bytes4 internal constant SET_PENDING_VALIDATORS_SEL = bytes4(keccak256("setPendingValidators(address[])"));
    bytes4 internal constant SET_VALIDATOR_INDEX_SEL = bytes4(keccak256("setValidatorIndex(address,uint)"));
    bytes4 internal constant SET_VALIDATORS_SEL = bytes4(keccak256("setValidators(address[])"));
    bytes4 internal constant VOTE_SEL = bytes4(keccak256("vote(bytes32,address,bool)"));

    // State

    bool internal completedInitialKeyCeremony;
    address public masterOfCeremony;
    address internal registry;
    bytes32 internal registryExecId;
    bytes32 internal appExecId;

    event ChangeFinalized(address[] validators);
    event InitiateChange(bytes32 indexed parent_hash, address[] validators);
    event InitializedRegistry(address indexed registry, bytes32 indexed registry_exec_id);
    event Report(address indexed validator, uint indexed block_number, bool indexed malicious, bytes proof);
    event Support(address indexed supporter, address indexed supported, bool indexed added);

    constructor(
        address _master_of_ceremony,
        address _registry_storage,
        address _init_registry,
        address _app_console,
        address _version_console,
        address _impl_console,
        address _consensus_init,
        address _validator_console,
        address _voting_console
    ) public {
        masterOfCeremony = _master_of_ceremony;
        initRegistry(_registry_storage, _init_registry, _app_console, _version_console, _impl_console);
        initConsensus(_consensus_init, _validator_console, _voting_console);
    }

    function initRegistry(
        address _registry_storage,
        address _init_registry,
        address _app_console,
        address _version_console,
        address _impl_console
    ) private {
        registry = new RegistryExec(this, this, _registry_storage, keccak256(bytes32(address(this))));
        RegistryExec _registry = RegistryExec(registry);

        registryExecId = _registry.initRegistry(_init_registry, _app_console, _version_console, _impl_console);
        require(registryExecId != bytes32(0));
        emit InitializedRegistry(_registry, registryExecId);

        _registry.registerApp(DEFAULT_CONSENSUS_APP_NAME, DEFAULT_CONSENSUS_APP_DESC);
    }

    function initConsensus(
        address _consensus_init,
        address _validator_console,
        address _voting_console
    ) private {
        bytes4[] memory _consensus_fn_sels = new bytes4[](2);
        _consensus_fn_sels[0] = ADD_VALIDATOR_SEL;
        _consensus_fn_sels[1] = ADD_PROPOSAL_SEL;

        address[] memory _consensus_fn_addrs = new address[](2);
        _consensus_fn_addrs[0] = _validator_console;
        _consensus_fn_addrs[1] = _voting_console;

        bytes memory _init_app_calldata = abi.encodeWithSelector(
            DEFAULT_CONSENSUS_APP_INIT_SEL,
            masterOfCeremony, 
            _validator_console, 
            _voting_console
        );

        deployConsensus(
            DEFAULT_CONSENSUS_APP_NAME, 
            DEFAULT_CONSENSUS_APP_VERSION, 
            _consensus_init,
            DEFAULT_CONSENSUS_APP_INIT_SEL, 
            _init_app_calldata,
            _consensus_fn_sels, 
            _consensus_fn_addrs, 
            DEFAULT_CONSENSUS_APP_VERSION_DESC, 
            DEFAULT_CONSENSUS_APP_INIT_DESC
        );
    }

    function deployConsensus(
        bytes32 _app_name,
        bytes32 _version_name,
        address _init,
        bytes4 _init_sel,
        bytes memory _init_calldata,
        bytes4[] memory _fn_sels, 
        address[] memory _fn_addrs,
        bytes memory _version_desc,
        bytes memory _init_desc
    ) public {
        address _voting_console = getVotingConsole();

        RegistryExec(registry).registerVersion(_app_name, _version_name, RegistryExec(registry).default_storage(), _version_desc);
        RegistryExec(registry).addFunctions(_app_name, _version_name, _fn_sels, _fn_addrs);

        if (appExecId == bytes32(0)) {
            // initial version
            finalizeConsensusVersion(_app_name, _version_name, _init, _init_sel, _init_calldata, _init_desc);
        } else if (_voting_console != address(0)) {
            bytes memory _finalize_calldata = abi.encodeWithSelector(FINALIZE_CONSENSUS_VERSION_SEL, _app_name, _version_name, _init, _init_sel, _init_calldata, _init_desc);
            bytes memory _add_proposal_calldata = abi.encodeWithSelector(ADD_ARBITRARY_PROPOSAL_SEL, msg.sender, this, uint(1), now, now + 90 days, "Upgrade consensus", _version_desc, _finalize_calldata);
            RegistryExec(registry).exec(_voting_console, _add_proposal_calldata);
        }
    }

    function finalizeConsensusVersion(
        bytes32 _app_name,
        bytes32 _version_name,
        address _init,
        bytes4 _init_sel,
        bytes memory _init_calldata,
        bytes memory _init_desc
    ) private {
        RegistryExec _registry = RegistryExec(registry);
        _registry.finalizeVersion(_app_name, _version_name, _init, _init_sel, _init_desc);

        ( , , appExecId) = _registry.initAppInstance(_app_name, false, _init_calldata);
        require(appExecId != bytes32(0));
    }

    function getFinalized() public view returns (bool) {
        bytes4 _get_finalized_sel = GET_FINALIZED_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return false;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_finalized_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getValidatorSupportCount(address _validator) public view returns (uint) {
        bytes4 _get_validator_support_count_sel = GET_VALIDATOR_SUPPORT_COUNT_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return 0;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_support_count_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                mstore(add(0x44, ptr), _validator)
                let ret := staticcall(gas, _delegate, ptr, 0x64, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getValidatorSupportDivisor() public view returns (uint) {
        bytes4 _get_validator_support_divisor_sel = GET_VALIDATOR_SUPPORT_DIVISOR_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return 2;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_support_divisor_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getMaximumValidatorCount() public view returns (uint) {
        bytes4 _get_validator_count_sel = GET_MAX_VALIDATOR_COUNT_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return getValidators().length;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_count_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getMinimumValidatorCount() public view returns (uint) {
        bytes4 _get_validator_count_sel = GET_MIN_VALIDATOR_COUNT_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return getValidators().length;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_count_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getValidators() public view returns (address[] memory _validators) {
        bytes4 _get_validators_sel = GET_VALIDATORS_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            _validators = new address[](1);
            _validators[0] = masterOfCeremony;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validators_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getValidatorCount() public view returns (uint) {
        bytes4 _get_validator_count_sel = GET_VALIDATOR_COUNT_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return getValidators().length;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_count_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getValidatorIndex(address _validator) internal view returns (uint _validator_index) {
        bytes4 _get_validator_index_sel = GET_VALIDATOR_INDEX_SEL;
        address _delegate = getDelegate();
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_validator_index_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            mstore(add(0x44, ptr), _validator)
            let ret := staticcall(gas, _delegate, ptr, 0x64, 0, 0)
            returndatacopy(0, 0, returndatasize)
            return(0, returndatasize)
        }
    }

    function getValidatorMetadata(address _validator) public view 
    returns(bytes32[] memory _validator_name,
            bytes32[] memory _validator_email,
            bytes32[] memory _validator_address_line_1,
            bytes32[] memory _validator_address_line_2,
            bytes32[] memory _validator_city,
            bytes32 _validator_state,
            bytes32 _validator_postal_code,
            bytes32 _validator_country,
            bytes32 _validator_phone) {
        bytes4 _get_validator_index_sel = GET_VALIDATOR_METADATA_SEL;
        address _delegate = getDelegate();
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_validator_index_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            mstore(add(0x44, ptr), _validator)
            let ret := staticcall(gas, _delegate, ptr, 0x64, 0, 0)
            returndatacopy(0, 0, returndatasize)
            return(0, returndatasize)
        }
    }

    function getPendingValidators() public view returns (address[] memory _validators) {
        bytes4 _get_pending_validators_sel = GET_PENDING_VALIDATORS_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return getValidators();
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_pending_validators_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function getPendingValidatorCount() public view returns (uint) {
        bytes4 _get_validator_count_sel = GET_PENDING_VALIDATOR_COUNT_SEL;
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return getValidators().length;
        } else {
            address _registry_storage = RegistryExec(registry).default_storage();
            bytes32 _exec_id = appExecId;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, _get_validator_count_sel)
                mstore(add(0x04, ptr), _registry_storage)
                mstore(add(0x24, ptr), _exec_id)
                let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
                returndatacopy(0, 0, returndatasize)
                return(0, returndatasize)
            }
        }
    }

    function finalizeChange() public onlySystem() onlyNotFinalized() {
        address _validator_console = getValidatorConsole();
        if (_validator_console == address(0)) {
            emit ChangeFinalized(getValidators());
        } else {
            bytes memory _set_validators_calldata = abi.encodeWithSelector(SET_VALIDATORS_SEL, getPendingValidators());
            RegistryExec(registry).exec(_validator_console, _set_validators_calldata);

            bytes memory _finalize_calldata = abi.encodeWithSelector(FINALIZE_CHANGE_SEL);
            RegistryExec(registry).exec(_validator_console, _finalize_calldata);

            emit ChangeFinalized(getValidators());
        }
    }

    // function addSupport(address _validator) public isValidator(msg.sender) isNotSupporting(_validator) withinMaximumValidatorLimit() {
    //     bytes memory _calldata = abi.encodeWithSelector(SET_VALIDATOR_SUPPORT_SEL, RegistryExec(registry).default_storage(), appExecId, msg.sender, _validator, true);
    //     RegistryExec(registry).exec(getValidatorConsole(), _calldata);
	// 	//validatorsStatus[msg.sender].supported.push(validator);
	// 	addValidator(_validator);
	// 	emit Support(msg.sender, _validator, true);
	// }

	// function removeSupport(address _sender, address _validator) private {
    //     bytes memory _calldata = abi.encodeWithSelector(SET_VALIDATOR_SUPPORT_SEL, RegistryExec(registry).default_storage(), appExecId, _sender, _validator, false);
    //     RegistryExec(registry).exec(getValidatorConsole(), _calldata);
	// 	// require(!isValidatorSupportedByPeer(_sender, _validator));
	// 	emit Support(_sender, _validator, false);
	// 	removeValidator(_validator);
	// }

    // function revokeAllSupported(address _validator) private {  // TODO: safety check?  this revokes all supported validators (ie upon validator removal)
	// 	address[] memory _revocation_list = getSupportedValidators(_validator);
	// 	for (uint i = 0; i < _revocation_list.length; i++) {
    //         removeSupport(_validator, _revocation_list[i]);
	// 	} 
    // }

    function addValidator(address _validator) public isSupportedByMajority(_validator) { // isNotValidator(_validator) 
        address[] memory _pendingValidators = getPendingValidators();

        bytes memory _add_validator_calldata = abi.encodeWithSelector(ADD_VALIDATOR_SEL, _validator, _pendingValidators.length);
        RegistryExec(registry).exec(getValidatorConsole(), _add_validator_calldata);

        address[] memory _newPendingValidators = new address[](_pendingValidators.length + 1);
        for (uint i = 0; i < _pendingValidators.length; i++) {
            _newPendingValidators[i] = _pendingValidators[i];
        }
        _newPendingValidators[_pendingValidators.length] = _validator;

        bytes memory _set_pending_validators_calldata = abi.encodeWithSelector(SET_PENDING_VALIDATORS_SEL, _newPendingValidators);
        RegistryExec(registry).exec(getValidatorConsole(), _set_pending_validators_calldata);

        if (_newPendingValidators.length == getMinimumValidatorCount()) {
            completedInitialKeyCeremony = true;
        }

        // bytes memory _set_validator_support_calldata = abi.encodeWithSelector(SET_VALIDATOR_SUPPORT_SEL, RegistryExec(registry).default_storage(), appExecId, _validator, _validator, true);
        // RegistryExec(registry).exec(getValidatorConsole(), _set_validator_support_calldata);

		initiateChange();
	}

	function removeValidator(address _validator) public isValidator(_validator) isNotSupportedByMajority(_validator) {
        uint _removed_validator_index = getValidatorIndex(_validator);

        address[] memory _pendingValidators = getPendingValidators();
        address _lastValidator = _pendingValidators[_pendingValidators.length - 1];
        _pendingValidators[_removed_validator_index] = _lastValidator;

        bytes memory _set_validator_idx_calldata = abi.encodeWithSelector(SET_VALIDATOR_INDEX_SEL, _lastValidator, _removed_validator_index);
        RegistryExec(registry).exec(getValidatorConsole(), _set_validator_idx_calldata);  // update the index of the last validator

        address[] memory _newPendingValidators = new address[](_pendingValidators.length - 1);
        _newPendingValidators = _pendingValidators;

        bytes memory _set_pending_validators_calldata = abi.encodeWithSelector(SET_PENDING_VALIDATORS_SEL, _newPendingValidators);
        RegistryExec(registry).exec(getValidatorConsole(), _set_pending_validators_calldata);

        bytes memory _remove_validator_calldata = abi.encodeWithSelector(REMOVE_VALIDATOR_SEL, _validator);
        RegistryExec(registry).exec(getValidatorConsole(), _remove_validator_calldata);

        // revokeAllSupported(_validator);
		initiateChange();
	}

    function initiateChange() private onlyFinalized() {
        address _validator_console = getValidatorConsole();
        if (_validator_console == address(0)) {
            emit InitiateChange(blockhash(block.number - 1), getPendingValidators());
        } else {
		    bytes memory _set_finalized_calldata = abi.encodeWithSelector(SET_FINALIZED_SEL, false);
            RegistryExec(registry).exec(_validator_console, _set_finalized_calldata);

		    emit InitiateChange(blockhash(block.number - 1), getPendingValidators());
        }
	}

    function reportBenign(address _validator, uint256 _block_number) public {
        address _validator_console = getValidatorConsole();
        if (_validator_console == address(0)) {
            emit Report(_validator, _block_number, false, new bytes(0));
        } else {
            bytes memory _calldata = abi.encodeWithSelector(REPORT_BENIGN_SEL, _validator, _block_number, false, new bytes(0));
            RegistryExec(registry).exec(_validator_console, _calldata);

            emit Report(_validator, _block_number, false, new bytes(0));
        }
    }

    function reportMalicious(address _validator, uint256 _block_number, bytes _proof) public {
        address _validator_console = getValidatorConsole();
        if (_validator_console == address(0)) {
            emit Report(_validator, _block_number, true, _proof);
        } else {
            bytes memory _calldata = abi.encodeWithSelector(REPORT_MALICIOUS_SEL, _validator, _block_number, true, _proof);
            RegistryExec(registry).exec(_validator_console, _calldata);

            emit Report(_validator, _block_number, true, _proof);
        }
    }

    function getDelegate() internal view returns (address delegate) {
        RegistryStorage _registry_storage = RegistryStorage(RegistryExec(registry).default_storage());
        if (_registry_storage != address(0) && registryExecId != bytes32(0) && appExecId != bytes32(0)) {
            bytes32 _provider_id = RegistryExec(registry).default_provider();
            bool is_payable;
            address storage_addr;
            bytes32 latest_version;
            address[] memory allowed;
            (is_payable, storage_addr, latest_version, delegate, allowed,) = _registry_storage.getAppInitInfo(registryExecId, _provider_id, DEFAULT_CONSENSUS_APP_NAME);
        }
    }

    function getValidatorConsole() public view returns (address) {
        bytes4 _get_validator_console_sel = GET_VALIDATOR_CONSOLE_SEL;
        address _delegate = getDelegate();
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        if (_exec_id == bytes32(0)) {
            return address(0);
        }
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_validator_console_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
            returndatacopy(0, 0, returndatasize)
            return(0, returndatasize)
        }
    }

    function getVotingConsole() public view returns (address) {
        bytes4 _get_voting_console_sel = GET_VOTING_CONSOLE_SEL;
        address _delegate = getDelegate();
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        if (_exec_id == bytes32(0)) {
            return address(0);
        }
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_voting_console_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
            returndatacopy(0, 0, returndatasize)
            return(0, returndatasize)
        }
    }

    modifier isSupportedByMajority(address _validator) {
        if (!completedInitialKeyCeremony && getPendingValidatorCount() < getMinimumValidatorCount()) {
            require(msg.sender == masterOfCeremony);
        } else {
            require(getValidatorSupportCount(_validator) > getPendingValidatorCount() / getValidatorSupportDivisor());
        }
        _;
    }

    modifier isNotSupportedByMajority(address _validator) {
        require(getValidatorSupportCount(_validator) <= getPendingValidatorCount() / getValidatorSupportDivisor());
        _;
    }

    modifier isNotSupporting(address _validator) {
        // require(!isValidatorSupportedByPeer(msg.sender, _validator));
        _;
    }

    modifier isValidator(address _validator) {
        address _delegate = getDelegate();
        bytes4 _get_validator_sel = GET_VALIDATOR_SEL;
        bytes32 _is_validator_retval = bytes32(0);
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_validator_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            mstore(add(0x44, ptr), _validator)
            let ret := staticcall(gas, _delegate, ptr, 0x44, 0, 0)
            returndatacopy(_is_validator_retval, 0x0, 0x20)
        }
		require(_is_validator_retval == bytes32(1));
		_;
	}

    modifier isNotValidator(address _validator) {
        address _delegate = getDelegate();
        bytes4 _get_validator_sel = GET_VALIDATOR_SEL;
        bytes32 _is_validator_retval = bytes32(0);
        address _registry_storage = RegistryExec(registry).default_storage();
        bytes32 _exec_id = appExecId;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _get_validator_sel)
            mstore(add(0x04, ptr), _registry_storage)
            mstore(add(0x24, ptr), _exec_id)
            mstore(add(0x44, ptr), _validator)
            let ret := staticcall(gas, _delegate, ptr, 0x64, 0, 0)
            returndatacopy(_is_validator_retval, 0x0, 0x20)
        }
		require(_is_validator_retval == bytes32(0));
		_;
    }

    modifier withinMinimumValidatorLimit() {
		require(getPendingValidatorCount() >= getMinimumValidatorCount());
		_;
	}

    modifier withinMaximumValidatorLimit() {
		require(getPendingValidatorCount() < getMaximumValidatorCount());
		_;
	}

    modifier onlyFinalized() {
		require(getFinalized());
		_;
	}

    modifier onlyMasterOfCeremony {
        require(msg.sender == masterOfCeremony);
        _;
    }

    modifier onlySystem() {
		require(msg.sender == SYSTEM_ADDRESS);
		_;
	}

    modifier onlyNotFinalized() {
		require(!getFinalized());
		_;
	}
}
