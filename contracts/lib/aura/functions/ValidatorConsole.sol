pragma solidity ^0.4.23;

import '../../auth_os.sol';

library ValidatorConsole {
  using LibEvents for uint;
  using LibPayments for uint;
  using LibStorage for uint;
  using MemoryBuffers for uint;
  using Pointers for *; 

  bytes32 internal constant FINALIZED = keccak256("finalized");
  bytes32 internal constant VALIDATOR_COUNT = keccak256("validator_count");
  bytes32 internal constant VALIDATORS = keccak256("validators");
  bytes32 internal constant PENDING_VALIDATOR_COUNT = keccak256("pending_validator_count");
  bytes32 internal constant PENDING_VALIDATORS = keccak256("pending_validators");

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

  bytes32 internal constant VALIDATOR_SUPPORT = keccak256("validator_support");
  bytes32 internal constant VALIDATOR_SUPPORT_COUNT = keccak256("validator_support_count");

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /*
  Add a validator.
  @param _validator: The validator address to add
  @param _index: The index at which the validator will exist in the validators list
  @return store_data: A formatted storage request
  */
  function addValidator(address _validator, uint _index) public pure
  returns (bytes memory store_data) {
    require(_validator != address(0));

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    ptr.store(bytes32(0)).at(FINALIZED);
    ptr.store(bytes32(_index)).at(keccak256(_validator, VALIDATOR_INDEX));
    ptr.store(bytes32(_validator)).at(keccak256(_validator, VALIDATOR_SEALING_PUBLIC_KEY));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_PAYOUT_PUBLIC_KEY));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_VOTING_PUBLIC_KEY));
    ptr.store(bytes32(1)).at(keccak256(_validator, VALIDATOR_IS_VALIDATOR));

    store_data = ptr.getBuffer();
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
    bytes32[] memory _validator_name,
    bytes32[] memory _validator_email,
    bytes32[] memory _validator_address_line_1,
    bytes32[] memory _validator_address_line_2,
    bytes32[] memory _validator_city,
    bytes32 _validator_state,
    bytes32 _validator_postal_code,
    bytes32 _validator_country,
    bytes32 _validator_phone
  ) public pure returns (bytes memory store_data) {
    require(_validator != address(0));

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    for (uint i = 0; i < _validator_name.length; i++) {
      ptr.store(bytes32(_validator_name[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATOR_NAME)));
    }

    for (i = 0; i < _validator_email.length; i++) {
      ptr.store(bytes32(_validator_email[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATOR_EMAIL)));
    }

    for (i = 0; i < _validator_address_line_1.length; i++) {
      ptr.store(bytes32(_validator_address_line_1[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_1)));
    }

    for (i = 0; i < _validator_address_line_2.length; i++) {
      ptr.store(bytes32(_validator_address_line_2[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_2)));
    }

    for (i = 0; i < _validator_city.length; i++) {
      ptr.store(bytes32(_validator_city[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_CITY)));
    }

    ptr.store(_validator_state).at(keccak256(_validator, VALIDATOR_ADDRESS_STATE));
    ptr.store(_validator_postal_code).at(keccak256(_validator, VALIDATOR_ADDRESS_POSTAL_CODE));
    ptr.store(_validator_country).at(keccak256(_validator, VALIDATOR_ADDRESS_COUNTRY));
    ptr.store(_validator_phone).at(keccak256(_validator, VALIDATOR_PHONE));

    store_data = ptr.getBuffer();
  }

  /*
  Remove a validator.
  @param _validator: The validator address to remove
  @return store_data: A formatted storage request
  */
  function removeValidator(address _validator) public pure
  returns (bytes memory store_data) {
    require(_validator != address(0));

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    ptr.store(bytes32(0)).at(FINALIZED);
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_INDEX));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_SEALING_PUBLIC_KEY));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_PAYOUT_PUBLIC_KEY));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_VOTING_PUBLIC_KEY));
    ptr.store(bytes32(0)).at(keccak256(_validator, VALIDATOR_IS_VALIDATOR));

    store_data = ptr.getBuffer();
  }

  /*
  Updates the given validator index.
  @param _validator: The validator address to add
  @param _index: The index at which the validator exists in the validators list
  @return store_data: A formatted storage request
  */
  function setValidatorIndex(address _validator, uint _index) public pure
  returns (bytes memory store_data) {
    require(_validator != address(0));

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
  
    ptr.store(bytes32(0)).at(FINALIZED);
    ptr.store(bytes32(_index)).at(keccak256(_validator, VALIDATOR_INDEX));

    store_data = ptr.getBuffer();
  }

  function setValidators(address[] memory _validators) public pure
  returns (bytes memory store_data) {
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
    ptr.store(bytes32(_validators.length)).at(VALIDATOR_COUNT);
    ptr.store(bytes32(_validators.length)).at(VALIDATORS);
    for (uint i = 0; i < _validators.length; i++) {
      ptr.store(bytes32(_validators[i])).at(bytes32((32 * (i + 1)) + uint(VALIDATORS)));
    }
    store_data = ptr.getBuffer();
  }

  function setPendingValidators(address[] memory _pending_validators) public pure
  returns (bytes memory store_data) {
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
    ptr.store(bytes32(_pending_validators.length)).at(PENDING_VALIDATOR_COUNT);
    ptr.store(bytes32(_pending_validators.length)).at(PENDING_VALIDATORS);
    for (uint i = 0; i < _pending_validators.length; i++) {
      ptr.store(bytes32(_pending_validators[i])).at(bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS)));
    }
    store_data = ptr.getBuffer();
  }

/*
  Update the finalized state to reflect the state of pending changes to the validator list.
  @param _finalized: The state of pending changes to the validator list
  @return store_data: A formatted storage request
  */
  function setFinalized(bool _finalized) public pure
  returns (bytes memory store_data) {
    bytes32 _finalized_val = _finalized ? bytes32(1) : bytes32(0);
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
    ptr.store(_finalized_val).at(FINALIZED);
    store_data = ptr.getBuffer();
  }

  function finalizeChange() public pure returns (bytes memory store_data) {
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
    ptr.store(bytes32(1)).at(FINALIZED);
    store_data = ptr.getBuffer();
  }

  function reportBenign(address _validator, uint256 _block_number) public pure returns (bytes memory store_data) {
    // emit Report(_validator, _block_number, false, new bytes(0));
    return new bytes(0);
  }

  function reportMalicious(address _validator, uint256 _block_number, bytes _proof) public pure returns (bytes memory store_data) {
    // emit Report(_validator, _block_number, true, _proof);
    return new bytes(0);
  }
}
