pragma solidity ^0.4.23;

import '../../../../auth_os.sol';

library ValidatorConsole {
  using Contract for *;
  using SafeMath for uint;
  using ArrayUtils for bytes32[];

  uint internal constant DEFAULT_MIN_KEY_CEREMONY_VALIDATORS = 12;
  uint internal constant DEFAULT_MAX_VALIDATOR_COUNT = 1024;
  uint internal constant DEFAULT_VALIDATOR_SUPPORT_DIVISOR = 2;

  bytes32 internal constant MASTER_OF_CEREMONY = keccak256("master_of_ceremony");
  bytes32 internal constant COMPLETED_INITIAL_KEY_CEREMONY = keccak256("completed_initial_key_ceremony");

  bytes32 internal constant FINALIZED = keccak256("finalized");
  bytes32 internal constant MAX_VALIDATOR_COUNT = keccak256("max_validator_count");
  bytes32 internal constant MIN_VALIDATOR_COUNT = keccak256("min_validator_count");

  bytes32 internal constant VALIDATORS = keccak256("validators");
  bytes32 internal constant PENDING_VALIDATORS = keccak256("pending_validators");

  bytes32 internal constant VALIDATOR_SUPPORT = keccak256("validator_support");
  bytes32 internal constant VALIDATOR_SUPPORT_COUNT = keccak256("validator_support_count");
  bytes32 internal constant VALIDATOR_SUPPORT_DIVISOR = keccak256("validator_support_divisor");

  bytes32 internal constant VALIDATOR_CONSOLE = keccak256("validator_console");
  bytes32 internal constant VOTING_CONSOLE = keccak256("voting_console");

  bytes32 internal constant VALIDATOR_NAME = keccak256("validator_name");
  bytes32 internal constant VALIDATOR_EMAIL = keccak256("validator_email");
  bytes32 internal constant VALIDATOR_PHONE = keccak256("validator_phone");
  bytes32 internal constant VALIDATOR_SEALING_PUBLIC_KEY = keccak256("validator_sealing_public_key");
  bytes32 internal constant VALIDATOR_PAYOUT_PUBLIC_KEY = keccak256("validator_payout_public_key");
  bytes32 internal constant VALIDATOR_VOTING_PUBLIC_KEY = keccak256("validator_voting_public_key");
  bytes32 internal constant VALIDATOR_ADDRESS_LINE_1 = keccak256("validator_address_line_1");
  bytes32 internal constant VALIDATOR_ADDRESS_LINE_2 = keccak256("validator_address_line_2");
  bytes32 internal constant VALIDATOR_ADDRESS_CITY = keccak256("validator_address_city");
  bytes32 internal constant VALIDATOR_ADDRESS_STATE = keccak256("validator_address_state");
  bytes32 internal constant VALIDATOR_ADDRESS_POSTAL_CODE = keccak256("validator_address_postal_code");
  bytes32 internal constant VALIDATOR_ADDRESS_COUNTRY = keccak256("validator_address_country");
  bytes32 internal constant VALIDATOR_INDEX = keccak256("validator_index");
  bytes32 internal constant VALIDATOR_IS_VALIDATOR = keccak256("validator_is_validator");

  bytes32 internal constant CHANGE_FINALIZED = keccak256("ChangeFinalized(address[])");
  bytes32 internal constant REPORT_VALIDATOR = keccak256("Report(address,uint,bool,bytes)");

  function getFinalized(
  ) public view returns (bool) {
    return bytes32(Contract.read(FINALIZED)) == bytes32(1);
  }

  function getMaximumValidatorCount(
  ) public view returns (uint) {
    
    return uint(Contract.read(MAX_VALIDATOR_COUNT));
  }

  function getMinimumValidatorCount(
  ) public view returns (uint) {
    return uint(Contract.read(MIN_VALIDATOR_COUNT));
  }

  function getValidators() public view returns (address[] memory) {
    uint _validators_count = getValidatorCount();
    bytes32[] memory _validators = new bytes32[](_validators_count);
    for (uint i = 0; i < _validators_count; i++) {
      _validators[i] = Contract.read(bytes32((32 * (i + 1)) + uint(VALIDATORS)));
    }

    return _validators.toAddressArr();
  }

  function getPendingValidators() public view returns (address[] memory) {
    uint _pending_validators_count = getPendingValidatorCount();
    bytes32[] memory _pending_validators = new bytes32[](_pending_validators_count);
    for (uint i = 0; i < _pending_validators_count; i++) {
      _pending_validators[i] = Contract.read(bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS)));
    }

    return _pending_validators.toAddressArr();
  }

  function getValidator(
    address _validator
  ) public view returns (uint _validator_index,
                         address _validator_sealing_key,
                         address _validator_payout_key,
                         address _validator_voting_key,
                         bool _is_validator) {
    require(_validator != address(0));

    _validator_index = uint(Contract.read(keccak256(_validator, VALIDATOR_INDEX)));
    _validator_sealing_key = address(Contract.read(keccak256(_validator, VALIDATOR_INDEX)));
    _validator_payout_key = address(Contract.read(keccak256(_validator, VALIDATOR_INDEX)));
    _validator_voting_key = address(Contract.read(keccak256(_validator, VALIDATOR_INDEX)));
    _is_validator = bytes32(Contract.read(keccak256(_validator, VALIDATOR_IS_VALIDATOR))) == bytes32(1);
  }

  function getValidatorCount() public view returns (uint) {
    return uint(Contract.read(VALIDATORS));
  }

  function getPendingValidatorCount() public view returns (uint) {
    return uint(Contract.read(PENDING_VALIDATORS));
  }

  function isValidator(
    address _validator
  ) public view returns (bool) {
    require(_validator != address(0));
    return bytes32(Contract.read(keccak256(_validator, VALIDATOR_IS_VALIDATOR))) == bytes32(1);
  }

  function getValidatorSupportCount(
    address _addr
  ) public view returns (uint) {
    require(_addr != address(0));
    return uint(Contract.read(keccak256(_addr, VALIDATOR_SUPPORT_COUNT)));
  }

  function getValidatorSupportDivisor() public view returns (uint) {
    return uint(Contract.read(VALIDATOR_SUPPORT_DIVISOR));
  }
  
  /*
  Add a validator.
  @param _validator: The validator address to add
  @param _index: The index at which the validator will exist in the validators list
  @return store_data: A formatted storage request
  */
  function addValidator(address _validator) public view {
    require(_validator != address(0) && !isValidator(_validator));

    Contract.authorize(msg.sender);
    Contract.storing();
  
    Contract.set(FINALIZED).to(false);
    Contract.set(keccak256(_validator, VALIDATOR_INDEX)).to(_pendingValidators.length);
    Contract.set(keccak256(_validator, VALIDATOR_SEALING_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_PAYOUT_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_VOTING_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_IS_VALIDATOR)).to(true);

    address[] memory _pendingValidators = getPendingValidators();
    address[] memory _newPendingValidators = new address[](_pendingValidators.length + 1);
    for (uint i = 0; i < _pendingValidators.length; i++) {
        _newPendingValidators[i] = _pendingValidators[i];
    }
    _newPendingValidators[_pendingValidators.length] = _validator;
    setPendingValidators(_newPendingValidators);

    if (_newPendingValidators.length == getMinimumValidatorCount()) {
        Contract.set(COMPLETED_INITIAL_KEY_CEREMONY).to(true);
    }

    Contract.commit();
  }

  /*
  Update validator.
  @param _validator: The validator address to add
  @param _validator_name: The legal name of the validator
  @param _validator_email: The validator's email address
  @param _validator_address_line_1: The validator's physical address, line 1
  @param _validator_address_line_2: The validator's physical address, line 2
  @param _validator_city: The city in which the validator is phyiscally located
  @param _validator_state: The state in which the validator is physically located
  @param _validator_postal_code: The postal code in which the validator is physically located
  @param _validator_country: The country in which the validator is physically located
  @param _validator_phone: The validator's phone number
  @return store_data: A formatted storage request
  */
  function setValidatorMetadata(
    address _validator,
    bytes32[] _validator_name,
    bytes32[] _validator_email,
    bytes32[] _validator_address_line_1,
    bytes32[] _validator_address_line_2,
    bytes32[] _validator_city,
    bytes32 _validator_state,
    bytes32 _validator_postal_code,
    bytes32 _validator_country,
    bytes32 _validator_phone
  ) public view  {
    require(_validator != address(0));

    Contract.authorize(msg.sender);
    Contract.storing();

    for (uint i = 0; i < _validator_name.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATOR_NAME))).to(bytes32(_validator_name[i]));
    }

    for (i = 0; i < _validator_email.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATOR_EMAIL))).to(bytes32(_validator_email[i]));
    }

    for (i = 0; i < _validator_address_line_1.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_1))).to(bytes32(_validator_address_line_1[i]));
    }

    for (i = 0; i < _validator_address_line_2.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_2))).to(bytes32(_validator_address_line_2[i]));
    }

    for (i = 0; i < _validator_city.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_CITY))).to(bytes32(_validator_city[i]));
    }
  
    Contract.set(keccak256(_validator, VALIDATOR_ADDRESS_STATE)).to(_validator_state);
    Contract.set(keccak256(_validator, VALIDATOR_ADDRESS_POSTAL_CODE)).to(_validator_postal_code);
    Contract.set(keccak256(_validator, VALIDATOR_ADDRESS_COUNTRY)).to(_validator_country);
    Contract.set(keccak256(_validator, VALIDATOR_PHONE)).to(_validator_phone);

    Contract.commit();
  }

  /*
  Remove a validator.
  @param _validator: The validator address to remove
  @return store_data: A formatted storage request
  */
  function removeValidator(address _validator) public view {
    require(_validator != address(0));

    Contract.authorize(msg.sender);
    Contract.storing();
  
    Contract.set(FINALIZED).to(false);
    Contract.set(keccak256(_validator, VALIDATOR_INDEX)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_SEALING_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_PAYOUT_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_VOTING_PUBLIC_KEY)).to(bytes32(0));
    Contract.set(keccak256(_validator, VALIDATOR_IS_VALIDATOR)).to(false);

    //     address[] memory _pendingValidators = getPendingValidators();
    //     address _lastValidator = _pendingValidators[_pendingValidators.length - 1];
    //     _pendingValidators[_removed_validator_index] = _lastValidator;

    //     bytes memory _set_validator_idx_calldata = abi.encodeWithSelector(SET_VALIDATOR_INDEX_SEL, _lastValidator, _removed_validator_index);
    //     RegistryExec(registry).exec(appExecId, _set_validator_idx_calldata);  // update the index of the last validator

    //     address[] memory _newPendingValidators = new address[](_pendingValidators.length - 1);
    //     _newPendingValidators = _pendingValidators;

    //     bytes memory _set_pending_validators_calldata = abi.encodeWithSelector(SET_PENDING_VALIDATORS_SEL, _newPendingValidators);
    //     RegistryExec(registry).exec(appExecId, _set_pending_validators_calldata);

    //     bytes memory _remove_validator_calldata = abi.encodeWithSelector(REMOVE_VALIDATOR_SEL, _validator);
    //     RegistryExec(registry).exec(appExecId, _remove_validator_calldata);

    //     // revokeAllSupported(_validator);
		// //initiateChange();

    Contract.commit();
  }

  /*
  Updates the given validator index.
  @param _validator: The validator address to add
  @param _index: The index at which the validator exists in the validators list
  @return store_data: A formatted storage request
  */
  function setValidatorIndex(address _validator, uint _index) public view {
    require(_validator != address(0));

    Contract.authorize(msg.sender);
    Contract.storing();
  
    Contract.set(FINALIZED).to(false);
    Contract.set(keccak256(_validator, VALIDATOR_INDEX)).to(_index);

    Contract.commit();
  }

  function setValidators(address[] _validators) public view {
    Contract.authorize(msg.sender);
    Contract.storing();

    Contract.set(VALIDATORS).to(_validators.length);
    for (uint i = 0; i < _validators.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(VALIDATORS))).to(bytes32(_validators[i]));
    }

    Contract.commit();
  }

  function setPendingValidators(address[] _pending_validators) public view {
    // Contract.storing();

    Contract.set(PENDING_VALIDATORS).to(_pending_validators.length);
    for (uint i = 0; i < _pending_validators.length; i++) {
      Contract.set(bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS))).to(bytes32(_pending_validators[i]));
    }

    // Contract.commit();
  }

/*
  Update the finalized state to reflect the state of pending changes to the validator list.
  @param _finalized: The state of pending changes to the validator list
  @return store_data: A formatted storage request
  */
  function setFinalized(bool _finalized) public view {
    Contract.authorize(msg.sender);
    Contract.storing();
    Contract.set(FINALIZED).to(_finalized);
    Contract.commit();
  }

  function finalizeChange() public view {
    Contract.storing();
    Contract.set(FINALIZED).to(true);
    Contract.commit();

    // Contract.emitting();
    // Contract.log([CHANGE_FINALIZED, _pending_valdators]);
  }

  function reportBenign(address _validator, uint256 _block_number) public view {
    Contract.authorize(msg.sender);
    // Contract.emitting();
    // Contract.log([REPORT_VALIDATOR, _validator, _block_number, false, new bytes(0)]);
  }

  function reportMalicious(address _validator, uint256 _block_number, bytes _proof) public view {
    Contract.authorize(msg.sender);
    // Contract.emitting();
    // Contract.log([REPORT_VALIDATOR, _validator, _block_number, true, _proof]);
  }
}
