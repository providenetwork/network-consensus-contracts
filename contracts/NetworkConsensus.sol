pragma solidity ^0.4.23;

import './lib/auth_os.sol';
import './lib/aura/contracts/IAura.sol';

/*
Network consensus.

See https://wiki.parity.io/Aura
*/
contract NetworkConsensus {

    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    // Default app constants

    bytes4 internal constant EXEC_SEL = bytes4(keccak256('exec(address,bytes32,bytes)'));

    bytes32 internal constant DEFAULT_CONSENSUS_APP_NAME = "Aura";
    bytes32 internal constant DEFAULT_CONSENSUS_APP_VERSION = "0.0.1";
    bytes internal constant DEFAULT_CONSENSUS_APP_VERSION_DESC = "Alpha authority round consensus";
    bytes4 internal constant DEFAULT_CONSENSUS_APP_INIT_SEL = bytes4(keccak256("init(address)"));

    // App selectors

    bytes4 internal constant ADD_ARBITRARY_PROPOSAL_SEL = bytes4(keccak256("addArbitraryProposal(address,bytes32,address,uint,uint,uint,bytes,bytes,bytes)"));
    bytes4 internal constant ADD_PROPOSAL_SEL = bytes4(keccak256("addProposal(address,uint,uint,uint,bytes,bytes,bytes32[])"));
    bytes4 internal constant ADD_VALIDATOR_SEL = bytes4(keccak256("addValidator(address)"));
    bytes4 internal constant INITIATE_CHANGE_SEL = bytes4(keccak256("initiateChange()"));
    bytes4 internal constant FINALIZE_CHANGE_SEL = bytes4(keccak256("finalizeChange()"));
    bytes4 internal constant FINALIZE_CONSENSUS_VERSION_SEL = bytes4(keccak256("finalizeConsensusVersion(bytes32,bytes32,address,bytes4,bytes,bytes)"));
    bytes4 internal constant GET_PROPOSALS_SEL = bytes4(keccak256("getProposals(address,bytes32)"));
    bytes4 internal constant GET_PROPOSALS_COUNT_SEL = bytes4(keccak256("getProposalsCount(address,bytes32)"));
    bytes4 internal constant IS_VALIDATOR_SEL = bytes4(keccak256("isValidator(address,bytes32,address)"));
    bytes4 internal constant REMOVE_VALIDATOR_SEL = bytes4(keccak256("removeValidator(address)"));
    bytes4 internal constant REPORT_BENIGN_SEL = bytes4(keccak256("report(address,uint,bool,bytes)"));
    bytes4 internal constant REPORT_MALICIOUS_SEL = bytes4(keccak256("report(address,uint,bool,bytes)"));
    bytes4 internal constant SET_FINALIZED_SEL = bytes4(keccak256("setFinalized(bool)"));
    bytes4 internal constant SET_PENDING_VALIDATORS_SEL = bytes4(keccak256("setPendingValidators(address[])"));
    bytes4 internal constant SET_VALIDATOR_INDEX_SEL = bytes4(keccak256("setValidatorIndex(address,uint)"));
    bytes4 internal constant SET_VALIDATORS_SEL = bytes4(keccak256("setValidators(address[])"));
    bytes4 internal constant VOTE_SEL = bytes4(keccak256("vote(bytes32,address,bool)"));

    // State

    address public master_of_ceremony;
    address internal abstract_storage;
    bytes32 internal registry_exec_id;
    bytes32 internal app_exec_id;

    event ChangeFinalized(address[] validators);
    event InitiateChange(bytes32 indexed parent_hash, address[] validators);
    event InitializedRegistry(address indexed registry, bytes32 indexed registry_exec_id);
    event Report(address indexed validator, uint indexed block_number, bool indexed malicious, bytes proof);
    event Support(address indexed supporter, address indexed supported, bool indexed added);

    event StorageException(bytes32 indexed execution_id, string message);

    constructor(
        address _master_of_ceremony,
        address _abstract_storage,
        address _registry_idx,
        address _registry_impl,
        address _consensus_idx,
        address _validator_console,
        address _voting_console
    ) public {
        master_of_ceremony = _master_of_ceremony;
        abstract_storage = _abstract_storage;
        initRegistry(_registry_idx, _registry_impl);
        initConsensus(_consensus_idx, _validator_console, _voting_console);
    }

    function initRegistry(
        address _registry_idx,
        address _registry_impl
    ) private {
        AbstractStorage _abstract_storage = AbstractStorage(abstract_storage);
        registry_exec_id = _abstract_storage.createRegistry(_registry_idx, _registry_impl);
        require(registry_exec_id != bytes32(0), "Failed to initialize registry");
    }

    function initConsensus(
        address _consensus_idx,
        address _validator_console,
        address _voting_console
    ) private {
        bytes4[] memory _consensus_fn_sels = new bytes4[](8);
        _consensus_fn_sels[0] = ADD_VALIDATOR_SEL;
        _consensus_fn_sels[1] = FINALIZE_CHANGE_SEL;
        _consensus_fn_sels[2] = INITIATE_CHANGE_SEL;
        _consensus_fn_sels[3] = REMOVE_VALIDATOR_SEL;
        _consensus_fn_sels[4] = SET_VALIDATORS_SEL;
        _consensus_fn_sels[5] = SET_VALIDATOR_INDEX_SEL;
        _consensus_fn_sels[6] = SET_PENDING_VALIDATORS_SEL;
        _consensus_fn_sels[7] = ADD_PROPOSAL_SEL;

        address[] memory _consensus_fn_addrs = new address[](8);
        _consensus_fn_addrs[0] = _validator_console;
        _consensus_fn_addrs[1] = _validator_console;
        _consensus_fn_addrs[2] = _validator_console;
        _consensus_fn_addrs[3] = _validator_console;
        _consensus_fn_addrs[4] = _validator_console;
        _consensus_fn_addrs[5] = _validator_console;
        _consensus_fn_addrs[6] = _validator_console;
        _consensus_fn_addrs[7] = _voting_console;

        bytes memory _init_calldata = abi.encodeWithSelector(
            DEFAULT_CONSENSUS_APP_INIT_SEL,
            master_of_ceremony
        );

        deployConsensus(
            DEFAULT_CONSENSUS_APP_NAME, 
            DEFAULT_CONSENSUS_APP_VERSION,
            _consensus_idx,
            _init_calldata,
            _consensus_fn_sels, 
            _consensus_fn_addrs
        );
    }

    function deployConsensus(
        bytes32 _app_name,
        bytes32 _version_name,
        address _consensus_idx,
        bytes memory _init_calldata,
        bytes4[] memory _fn_sels, 
        address[] memory _fn_addrs
    ) public {
        require(registry_exec_id != bytes32(0), "Unable to deploy network consensus version without valid registry");
        AbstractStorage _abstract_storage = AbstractStorage(abstract_storage);

        if (app_exec_id == bytes32(0)) {
            // initial version
            bytes4 _sel = bytes4(keccak256("registerApp(bytes32,address,bytes4[],address[])"));
            bytes memory _calldata = abi.encodeWithSelector(_sel, _app_name, _consensus_idx, _fn_sels, _fn_addrs);
            bytes memory _exec_calldata = abi.encodeWithSelector(EXEC_SEL, this, registry_exec_id, _calldata);
            require(abstract_storage.call(_exec_calldata), "Failed to register application");

            _sel = bytes4(keccak256("registerAppVersion(bytes32,bytes32,address,bytes4[],address[])"));
            _calldata = abi.encodeWithSelector(_sel, _app_name, _version_name, _consensus_idx, _fn_sels, _fn_addrs);
            _exec_calldata = abi.encodeWithSelector(EXEC_SEL, this, registry_exec_id, _calldata);
            require(abstract_storage.call(_exec_calldata), "Failed to register application version");

            (app_exec_id, ) = _abstract_storage.createInstance(this, _app_name, this, registry_exec_id, _init_calldata);
            require(app_exec_id != bytes32(0), "Failed to initialize application");
        } else {
            // bytes memory _finalize_calldata = abi.encodeWithSelector(FINALIZE_CONSENSUS_VERSION_SEL, _app_name, _version_name, _init, _init_sel, _init_calldata, _init_desc);
            // bytes memory _add_proposal_calldata = abi.encodeWithSelector(ADD_ARBITRARY_PROPOSAL_SEL, abstract_storage;, app_exec_id, msg.sender, this, uint(1), now, now + 90 days, "Upgrade consensus", _version_desc, _finalize_calldata);
            // RegistryExec(registry).exec(_voting_console, _add_proposal_calldata);
        }
    }

    // Executes an arbitrary function in this application
    function exec(bytes _calldata) internal returns (bool success) {
        require(app_exec_id != 0 && _calldata.length >= 4);
        AbstractStorage(abstract_storage).exec(this, app_exec_id, _calldata);
        success = checkReturn();
        if (!success) checkErrors();
    }
    
    function checkReturn() internal pure returns (bool success) {
      success = false;
      assembly {
          // returndata size must be 0x60 bytes
          if eq(returndatasize, 0x60) {
              // Copy returned data to pointer and check that at least one value is nonzero
              let ptr := mload(0x40)
              returndatacopy(ptr, 0, returndatasize)
              if iszero(iszero(mload(ptr))) { success := 1 }
              if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
              if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
            }
        }
        return success;
    }

    // Checks to see if an error message was returned with the failed call, and emits it if so -
    function checkErrors() internal {
        // If the returned data begins with selector 'Error(string)', get the contained message -
        string memory message;
        bytes4 err_sel = bytes4(keccak256('Error(string)'));
        assembly {
            // Get pointer to free memory, place returned data at pointer, and update free memory pointer
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            mstore(0x40, add(ptr, returndatasize))

            // Check value at pointer for equality with Error selector -
            if eq(mload(ptr), and(err_sel, 0xffffffff00000000000000000000000000000000000000000000000000000000)) {
                message := add(0x24, ptr)
            }
        }
        // If no returned message exists, emit a default error message. Otherwise, emit the error message
        if (bytes(message).length == 0) {
            emit StorageException(app_exec_id, "No error recieved");
        } else {
            emit StorageException(app_exec_id, message);
        }
    }

    function getFinalized() public view returns (bool) {
        return IAura(getDelegate()).getFinalized(abstract_storage, app_exec_id);
    }

    function getValidatorSupportCount(address _validator) public view returns (uint) {
        return IAura(getDelegate()).getValidatorSupportCount(abstract_storage, app_exec_id, _validator);
    }

    function getValidatorSupportDivisor() public view returns (uint) {
        address _delegate = getDelegate();
        if (_delegate == address(0)) {
            return 2;
        } else {
            return IAura(getDelegate()).getValidatorSupportDivisor(abstract_storage, app_exec_id);
        }
    }

    function getMaximumValidatorCount() public view returns (uint) {
        return IAura(getDelegate()).getMaximumValidatorCount(abstract_storage, app_exec_id);
    }

    function getMinimumValidatorCount() public view returns (uint) {
        return IAura(getDelegate()).getMinimumValidatorCount(abstract_storage, app_exec_id);
    }

    function getValidators() public view returns (address[] memory _validators) {
        return IAura(getDelegate()).getValidators(abstract_storage, app_exec_id);
    }

    function getValidatorCount() public view returns (uint) {
        return IAura(getDelegate()).getValidatorCount(abstract_storage, app_exec_id);
    }

    function getValidatorIndex(address _validator) internal view returns (uint _validator_index) {
        return IAura(getDelegate()).getValidatorIndex(abstract_storage, app_exec_id, _validator);
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
        return IAura(getDelegate()).getValidatorMetadata(abstract_storage, app_exec_id, _validator);
    }

    function getPendingValidators() public view returns (address[] memory _validators) {
        return IAura(getDelegate()).getPendingValidators(abstract_storage, app_exec_id);

    }

    function getPendingValidatorCount() public view returns (uint) {
        return IAura(getDelegate()).getPendingValidatorCount(abstract_storage, app_exec_id);
    }

    function getProposals() public view returns (address[] memory _proposals) {
        // return IAura(getDelegate()).getProposals(abstract_storage, app_exec_id);
    }

    function getProposalsCount() public view returns (uint) {
        return IAura(getDelegate()).getProposalsCount(abstract_storage, app_exec_id);
    }

    function finalizeChange() public onlySystem() onlyNotFinalized() {
        bytes memory _set_validators_calldata = abi.encodeWithSelector(SET_VALIDATORS_SEL, getPendingValidators());
        require(exec(_set_validators_calldata));
        require(exec(abi.encodeWithSelector(FINALIZE_CHANGE_SEL)));
        emit ChangeFinalized(getValidators());
    }

    // function addSupport(address _validator) public isValidator(msg.sender) isNotSupporting(_validator) withinMaximumValidatorLimit() {
    //     bytes memory _calldata = abi.encodeWithSelector(SET_VALIDATOR_SUPPORT_SEL, abstract_storage;, app_exec_id, msg.sender, _validator, true);
    //     RegistryExec(registry).exec(getValidatorConsole(), _calldata);
	// 	//validatorsStatus[msg.sender].supported.push(validator);
	// 	addValidator(_validator);
	// 	emit Support(msg.sender, _validator, true);
	// }

	// function removeSupport(address _sender, address _validator) private {
    //     bytes memory _calldata = abi.encodeWithSelector(SET_VALIDATOR_SUPPORT_SEL, abstract_storage;, app_exec_id, _sender, _validator, false);
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

    function addValidator(address _validator) public isNotValidator(_validator) isSupportedByMajority(_validator) {
        require(exec(abi.encodeWithSelector(ADD_VALIDATOR_SEL, _validator)));
    }

	function removeValidator(address _validator) public isValidator(_validator) isNotSupportedByMajority(_validator) {
        require(exec(abi.encodeWithSelector(REMOVE_VALIDATOR_SEL, _validator)));
    }

    function initiateChange() private onlyFinalized() {
        require(exec(abi.encodeWithSelector(SET_FINALIZED_SEL, false)));
        // emit InitiateChange(blockhash(block.number - 1), getPendingValidators());
    }

    function reportBenign(address _validator, uint256 _block_number) public {
        bytes memory _calldata = abi.encodeWithSelector(REPORT_BENIGN_SEL, _validator, _block_number, false, new bytes(0));
        require(exec(_calldata));
    }

    function reportMalicious(address _validator, uint256 _block_number, bytes _proof) public {
        bytes memory _calldata = abi.encodeWithSelector(REPORT_MALICIOUS_SEL, _validator, _block_number, true, _proof);
        require(exec(_calldata));
    }

    function getDelegate() public view returns (address delegate) {
        return StorageInterface(abstract_storage).getIndex(app_exec_id);
    }

    function isInitialKeyCeremonyCompleted() internal returns (bool) {
        return IAura(getDelegate()).isInitialKeyCeremonyCompleted(abstract_storage, app_exec_id);
    }

    modifier isSupportedByMajority(address _validator) {
        if (!isInitialKeyCeremonyCompleted() && getPendingValidatorCount() < getMinimumValidatorCount()) {
            require(msg.sender == master_of_ceremony);
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
        require(IAura(getDelegate()).isValidator(abstract_storage, app_exec_id, _validator));
        _;
    }

    modifier isNotValidator(address _validator) {
        require(!IAura(getDelegate()).isValidator(abstract_storage, app_exec_id, _validator));
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

    modifier onlymaster_of_ceremony {
        require(msg.sender == master_of_ceremony);
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
