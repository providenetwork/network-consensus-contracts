pragma solidity ^0.4.23;

import '../../../auth_os.sol';

library Aura {
  using Exceptions for bytes32;
  using LibEvents for uint;
  using LibPayments for uint;
  using LibStorage for uint;
  using MemoryBuffers for uint;
  using Pointers for *; 

  // Validator console

  uint internal constant DEFAULT_MAX_VALIDATOR_COUNT = 25;
  uint internal constant DEFAULT_VALIDATOR_SUPPORT_DIVISOR = 2;

  bytes32 internal constant FINALIZED = keccak256("finalized");
  bytes32 internal constant MASTER_OF_CEREMONY = keccak256("master_of_ceremony");
  bytes32 internal constant MAX_VALIDATOR_COUNT = keccak256("max_validator_count");

  bytes32 internal constant VALIDATOR_NAME = keccak256("validator_name");
  bytes32 internal constant VALIDATOR_SEALING_PUBLIC_KEY = keccak256("validator_sealing_public_key");
  bytes32 internal constant VALIDATOR_PAYOUT_PUBLIC_KEY = keccak256("validator_payout_public_key");
  bytes32 internal constant VALIDATOR_VOTING_PUBLIC_KEY = keccak256("validator_voting_public_key");
  bytes32 internal constant VALIDATOR_ADDRESS_LINE_1 = keccak256("validator_address_line_1");
  bytes32 internal constant VALIDATOR_ADDRESS_LINE_2 = keccak256("validator_address_line_2");
  bytes32 internal constant VALIDATOR_ADDRESS_CITY = keccak256("validator_address_city");
  bytes32 internal constant VALIDATOR_ADDRESS_STATE = keccak256("validator_address_state");
  bytes32 internal constant VALIDATOR_ADDRESS_POSTAL_CODE = keccak256("validator_address_postal_code");
  bytes32 internal constant VALIDATOR_INDEX = keccak256("validator_index");
  bytes32 internal constant VALIDATOR_IS_VALIDATOR = keccak256("validator_is_validator");

  bytes32 internal constant VALIDATOR_COUNT = keccak256("validator_count");
  bytes32 internal constant VALIDATOR_SUPPORT_COUNT = keccak256("validator_support_count");
  bytes32 internal constant VALIDATOR_SUPPORT_DIVISOR = keccak256("validator_support_divisor");
  bytes32 internal constant VALIDATORS = keccak256("validators");
  bytes32 internal constant PENDING_VALIDATOR_COUNT = keccak256("pending_validator_count");
  bytes32 internal constant PENDING_VALIDATORS = keccak256("pending_validators");

  bytes32 internal constant VALIDATOR_CONSOLE = keccak256("validator_console");
  bytes32 internal constant VOTING_CONSOLE = keccak256("voting_console");

  // Voting console

  bytes32 internal constant CANDIDATES = keccak256("candidates");
  bytes32 internal constant CANDIDATE_COUNT = keccak256("candidate_count");
  bytes32 internal constant CREATOR = keccak256("creator");
  bytes32 internal constant DATA = keccak256("data");
  bytes32 internal constant PROPOSAL = keccak256("proposal");
  bytes32 internal constant PROPOSALS = keccak256("proposals");
  bytes32 internal constant PROPOSED_CALLDATA = keccak256("proposed_calldata");
  bytes32 internal constant PROPOSED_TARGET = keccak256("proposed_target");
  bytes32 internal constant START_TIMESTAMP = keccak256("start_timestamp");
  bytes32 internal constant EXPIRY_TIMESTAMP = keccak256("expiry_timestamp");
  bytes32 internal constant STATUS = keccak256("status");
  bytes32 internal constant TITLE = keccak256("title");
  bytes32 internal constant VOTE = keccak256("vote");
  bytes32 internal constant VOTE_COUNT = keccak256("vote_count");
  bytes32 internal constant VOTED = keccak256("voted");
  bytes32 internal constant VOTES = keccak256("votes");

  enum ProposalStatus { Pending, Passed, Expired, Failed }

  // Selectors

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  function init(
    address _master_of_ceremony,
    address _validator_console,
    address _voting_console
  ) public pure returns (bytes memory store_data) {
    require(_master_of_ceremony != address(0));

    address[] memory _validators = new address[](1);
    _validators[0] = _master_of_ceremony;

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    ptr.store(bytes32(0)).at(FINALIZED);

    ptr.store(bytes32(_master_of_ceremony)).at(MASTER_OF_CEREMONY);
    ptr.store(bytes32(1)).at(keccak256(_master_of_ceremony, VALIDATOR_SUPPORT_COUNT));

    ptr.store(bytes32(DEFAULT_MAX_VALIDATOR_COUNT)).at(MAX_VALIDATOR_COUNT);
    ptr.store(bytes32(DEFAULT_VALIDATOR_SUPPORT_DIVISOR)).at(VALIDATOR_SUPPORT_DIVISOR);

    ptr.store(bytes32(_validators.length)).at(VALIDATOR_COUNT);
    ptr.store(bytes32(_validators.length)).at(VALIDATORS);
  
    ptr.store(bytes32(_validators.length)).at(PENDING_VALIDATOR_COUNT);
    ptr.store(bytes32(_validators.length)).at(PENDING_VALIDATORS);

    for (uint i = 0; i < _validators.length; i++) {
      address _validator = _validators[i];
      ptr.store(bytes32(_validator)).at(bytes32((32 * (i + 1)) + uint(VALIDATORS)));
      ptr.store(bytes32(_validator)).at(bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS)));
    }

    ptr.store(bytes32(_validator_console)).at(VALIDATOR_CONSOLE);
    ptr.store(bytes32(_voting_console)).at(VOTING_CONSOLE);

    store_data = ptr.toBuffer();
  }

  // Validator console getters

  function getFinalized(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(FINALIZED);
    bytes32 _finalized_val = ptr.readSingleFrom(_storage);
    return _finalized_val == bytes32(1);
  }

  function getMaximumValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(MAX_VALIDATOR_COUNT);
    return uint(ptr.readSingleFrom(_storage));
  }

  function getValidators(
    address _storage,
    bytes32 _exec_id
  ) public view returns (address[] memory) {
    require(_storage != address(0) && _exec_id != bytes32(0));

    uint _validator_count = getValidatorCount(_storage, _exec_id);

    uint ptr = MemoryBuffers.cdBuff(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(bytes32(_validator_count));

    // Loop over list length and place each index storage location in buffer
    for (uint i = 0; i < _validator_count; i++) {
      ptr.cdPush(bytes32((32 * (i + 1)) + uint(VALIDATORS)));
    }

    return readMultiAddressFrom(ptr, _storage);
  }

  function getPendingValidators(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (address[] memory) {
    require(_storage != address(0) && _exec_id != bytes32(0));

    uint _pending_validator_count = getPendingValidatorCount(_storage, _exec_id);

    uint ptr = MemoryBuffers.cdBuff(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(bytes32(_pending_validator_count));

    // Loop over list length and place each index storage location in buffer
    for (uint i = 0; i < _pending_validator_count; i++) {
      ptr.cdPush(bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS)));
    }

    return readMultiAddressFrom(ptr, _storage);
  }

  function getValidator(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (uint _validator_index,
                         address _validator_sealing_key,
                         address _validator_payout_key,
                         address _validator_voting_key,
                         bool _is_validator) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));

    uint ptr = MemoryBuffers.cdBuff(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_INDEX));
    ptr.cdPush(keccak256(_validator, VALIDATOR_SEALING_PUBLIC_KEY));
    ptr.cdPush(keccak256(_validator, VALIDATOR_PAYOUT_PUBLIC_KEY));
    ptr.cdPush(keccak256(_validator, VALIDATOR_VOTING_PUBLIC_KEY));
    ptr.cdPush(keccak256(_validator, VALIDATOR_IS_VALIDATOR));

    bytes32[] memory _retvals = ptr.readMultiFrom(_storage);
    assert(_retvals.length == 5);

    _validator_index = uint(_retvals[0]);
    _validator_sealing_key = address(_retvals[1]);
    _validator_payout_key = address(_retvals[2]);
    _validator_voting_key = address(_retvals[3]);
    _is_validator = _retvals[4] == bytes32(1);
  }

  function getValidatorMetadata(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns(bytes32[] memory _validator_name,
                        bytes32[] memory _validator_address_line_1,
                        bytes32[] memory _validator_address_line_2,
                        bytes32[] memory _validator_city,
                        bytes32 _validator_state,
                        bytes32 _validator_postal_code) {
    uint ptr = MemoryBuffers.cdBuff(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_ADDRESS_STATE));
    ptr.cdPush(keccak256(_validator, VALIDATOR_ADDRESS_POSTAL_CODE));

    bytes32[] memory _retvals = ptr.readMultiFrom(_storage);
    assert(_retvals.length == 2);

    _validator_state = _retvals[0];
    _validator_postal_code = _retvals[1];

    ptr.cdOverwrite(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_NAME));
    _validator_name = ptr.readMultiFrom(_storage);

    ptr.cdOverwrite(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_ADDRESS_LINE_1));
    _validator_address_line_1 = ptr.readMultiFrom(_storage);

    ptr.cdOverwrite(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_ADDRESS_LINE_2));
    _validator_address_line_2 = ptr.readMultiFrom(_storage);

    ptr.cdOverwrite(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(keccak256(_validator, VALIDATOR_ADDRESS_CITY));
    _validator_city = ptr.readMultiFrom(_storage);
  }

  function getValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(VALIDATOR_COUNT);
    return uint(ptr.readSingleFrom(_storage));
  }

  function getPendingValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(PENDING_VALIDATOR_COUNT);
    return uint(ptr.readSingleFrom(_storage));
  }

  function isValidator(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(_validator, VALIDATOR_IS_VALIDATOR));
    bytes32 _retval = ptr.readSingleFrom(_storage);
    return _retval == bytes32(1);
  }

  function getValidatorSupportCount(
    address _storage, 
    bytes32 _exec_id,
    address _addr
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(_addr, VALIDATOR_SUPPORT_COUNT));
    return uint(ptr.readSingleFrom(_storage));
  }

  function getValidatorSupportDivisor(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(VALIDATOR_SUPPORT_DIVISOR);
    return uint(ptr.readSingleFrom(_storage));
  }

  // Voting console getters

  function getProposalCandidates(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (bytes32[] memory) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));

    uint _candidate_count = getProposalCandidateCount(_storage, _exec_id, _proposal_id);

    uint ptr = MemoryBuffers.cdBuff(RD_MULTI);
    ptr.cdPush(_exec_id);
    ptr.cdPush(0x40);
    ptr.cdPush(bytes32(_candidate_count));

    for (uint i = 0; i < _candidate_count; i++) {
      ptr.cdPush(bytes32((32 * (i + 1)) + uint(keccak256(keccak256(_proposal_id, PROPOSAL), CANDIDATES))));
    }

    return ptr.readMultiFrom(_storage);
  }

  function getProposalCandidateCount(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));

    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), CANDIDATE_COUNT));
    return uint(ptr.readSingleFrom(_storage));
  }

  function getProposalExpired(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    if (getProposalIsFinalized(_storage, _exec_id, _proposal_id)) {
      return getProposalStatus(_storage, _exec_id, _proposal_id) == uint8(ProposalStatus.Expired);
    }
    uint _expiry_timestamp = getProposalExpiryTimestamp(_storage, _exec_id, _proposal_id);
    return now >= _expiry_timestamp;
  }

  function getProposalIsFinalized(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), FINALIZED));
    bytes32 _retval = ptr.readSingleFrom(_storage);
    return _retval == bytes32(1);
  }

  function getProposalStatus(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (uint8) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), STATUS));
    return uint8(ptr.readSingleFrom(_storage));
  }

  function getProposalStartTimestamp(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), START_TIMESTAMP));
    return uint(ptr.readSingleFrom(_storage));
  }

  function getProposalExpiryTimestamp(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), EXPIRY_TIMESTAMP));
    return uint(ptr.readSingleFrom(_storage));
  }

  function getProposalVoteCount(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), VOTE_COUNT));
    return uint(ptr.readSingleFrom(_storage));
  }

  function getProposalCandidateVoteCount(
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id,
    bytes32 _candidate
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _proposal_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(keccak256(keccak256(_proposal_id, PROPOSAL), keccak256(_candidate, VOTE_COUNT)));
    return uint(ptr.readSingleFrom(_storage));
  }

  // Console address getters

  function getValidatorConsole(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (address) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(VALIDATOR_CONSOLE);
    return address(ptr.readSingleFrom(_storage));
  }

  function getVotingConsole(
    address _storage,
    bytes32 _exec_id
  ) public view returns (address) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    uint ptr = MemoryBuffers.cdBuff(RD_SING);
    ptr.cdPush(_exec_id);
    ptr.cdPush(VOTING_CONSOLE);
    return address(ptr.readSingleFrom(_storage));
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The address to read from
  @return read_values: The values read from storage
  */
  function readMultiAddressFrom(uint _ptr, address _storage) internal view returns (address[] memory read_values) {
    bool success;
    assembly {
      // Minimum length for 'readMulti' - 1 location is 0x84
      if lt(mload(_ptr), 0x84) { revert (0, 0) }
      // Read from storage
      success := staticcall(gas, _storage, add(0x20, _ptr), mload(_ptr), 0, 0)
      // If call succeed, get return information
      if gt(success, 0) {
        // Ensure data will not be copied beyond the pointer
        if gt(sub(returndatasize, 0x20), mload(_ptr)) { revert (0, 0) }
        // Copy returned data to pointer, overwriting it in the process
        // Copies returndatasize, but ignores the initial read offset so that the bytes32[] returned in the read is sitting directly at the pointer
        returndatacopy(_ptr, 0x20, sub(returndatasize, 0x20))
        // Set return bytes32[] to pointer, which should now have the stored length of the returned array
        read_values := _ptr
      }
    }
    if (!success) {
      assembly {
        mstore(0, "StorageReadFailure")
        revert(0, 0x20)
      }
    }
  }
}
