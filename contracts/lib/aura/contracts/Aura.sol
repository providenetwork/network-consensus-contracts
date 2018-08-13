pragma solidity ^0.4.23;

import '../../auth_os.sol';

library Aura {
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

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');

  // Returns the storage location of a script execution address's permissions -
  function execPermissions(address _exec) internal pure returns (bytes32)
    { return keccak256(_exec, EXEC_PERMISSIONS); }

  function init(
    address _master_of_ceremony
  ) external view {
    require(_master_of_ceremony != address(0));

    Contract.initialize();
    Contract.storing();
  
    Contract.set(execPermissions(msg.sender)).to(true);
    // Contract.set(execPermissions(_network_consensus)).to(true);

    Contract.set(FINALIZED).to(false);
    Contract.set(COMPLETED_INITIAL_KEY_CEREMONY).to(false);

    Contract.set(MASTER_OF_CEREMONY).to(_master_of_ceremony);
    Contract.set(keccak256(_master_of_ceremony, VALIDATOR_SUPPORT_COUNT)).to(bytes32(1));

    Contract.set(MIN_VALIDATOR_COUNT).to(DEFAULT_MIN_KEY_CEREMONY_VALIDATORS);
    Contract.set(MAX_VALIDATOR_COUNT).to(DEFAULT_MAX_VALIDATOR_COUNT);
    Contract.set(VALIDATOR_SUPPORT_DIVISOR).to(DEFAULT_VALIDATOR_SUPPORT_DIVISOR);

    Contract.set(VALIDATORS).to(bytes32(1));
    Contract.set(PENDING_VALIDATORS).to(bytes32(1));

    Contract.set(bytes32(32 + uint(VALIDATORS))).to(bytes32(_master_of_ceremony));
    Contract.set(bytes32(32 + uint(PENDING_VALIDATORS))).to(bytes32(_master_of_ceremony));

    Contract.commit();
  }

  function getFinalized(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return bytes32(GetterInterface(_storage).read(_exec_id, FINALIZED)) == bytes32(1);
  }

  function getMaximumValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, MAX_VALIDATOR_COUNT));
  }

  function getMinimumValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, MIN_VALIDATOR_COUNT));
  }

  function getValidators(
    address _storage,
    bytes32 _exec_id
  ) public view returns (address[] memory) {
    require(_storage != address(0) && _exec_id != bytes32(0));

    uint _valdiators_count = getValidatorCount(_storage, _exec_id);
    bytes32[] memory arr_indices = new bytes32[](_valdiators_count);
    for (uint i = 0; i < _valdiators_count; i++) {
      arr_indices[i] = bytes32((32 * (i + 1)) + uint(VALIDATORS));
    }

    return GetterInterface(_storage).readMulti(_exec_id, arr_indices).toAddressArr();
  }

  function getPendingValidators(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (address[] memory) {
    require(_storage != address(0) && _exec_id != bytes32(0));

    uint _pending_valdiators_count = getPendingValidatorCount(_storage, _exec_id);
    bytes32[] memory arr_indices = new bytes32[](_pending_valdiators_count);
    for (uint i = 0; i < _pending_valdiators_count; i++) {
      arr_indices[i] = bytes32((32 * (i + 1)) + uint(PENDING_VALIDATORS));
    }

    return GetterInterface(_storage).readMulti(_exec_id, arr_indices).toAddressArr();
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

    _validator_index = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_INDEX)));
    _validator_sealing_key = address(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_INDEX)));
    _validator_payout_key = address(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_INDEX)));
    _validator_voting_key = address(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_INDEX)));
    _is_validator = bytes32(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_IS_VALIDATOR))) == bytes32(1);
  }

  function getValidatorMetadata(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns(bytes32[] _validator_name,
                        bytes32[] _validator_email,
                        bytes32[] _validator_address_line_1,
                        bytes32[] _validator_address_line_2,
                        bytes32[] _validator_city,
                        bytes32 _validator_state,
                        bytes32 _validator_postal_code,
                        bytes32 _validator_country,
                        bytes32 _validator_phone) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));

    _validator_name = getValidatorName(_storage, _exec_id, _validator);
    _validator_email = getValidatorEmail(_storage, _exec_id, _validator);
    _validator_address_line_1 = getValidatorAddressLine1(_storage, _exec_id, _validator);
    _validator_address_line_2 = getValidatorAddressLine2(_storage, _exec_id, _validator);
    _validator_city = getValidatorCity(_storage, _exec_id, _validator);
    _validator_state = GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_STATE));
    _validator_postal_code = GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_POSTAL_CODE));
    _validator_country = GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_COUNTRY));
    _validator_phone = GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_PHONE));
  }
  
  function getValidatorName(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bytes32[] _validator_name) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));
    uint _validator_name_length = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_NAME)));
    bytes32[] memory _validator_name_locs = new bytes32[](_validator_name_length);
    for (uint i = 0; i < _validator_name_length; i++) {
      _validator_name_locs[i] = bytes32((32 * (i + 1)) + uint(VALIDATOR_NAME));
    } 
    _validator_name = GetterInterface(_storage).readMulti(_exec_id, _validator_name_locs);
  }

  function getValidatorEmail(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bytes32[] _validator_email) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));
    uint _validator_email_length = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_EMAIL)));
    bytes32[] memory _validator_email_locs = new bytes32[](_validator_email_length);
    for (uint i = 0; i < _validator_email_length; i++) {
      _validator_email_locs[i] = bytes32((32 * (i + 1)) + uint(VALIDATOR_EMAIL));
    } 
    _validator_email = GetterInterface(_storage).readMulti(_exec_id, _validator_email_locs);
  }

  function getValidatorAddressLine1(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bytes32[] _validator_address_line_2) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));
    uint _validator_address_line_2_length = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_LINE_1)));
    bytes32[] memory _validator_address_line_2_locs = new bytes32[](_validator_address_line_2_length);
    for (uint i = 0; i < _validator_address_line_2_length; i++) {
      _validator_address_line_2_locs[i] = bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_1));
    } 
    _validator_address_line_2 = GetterInterface(_storage).readMulti(_exec_id, _validator_address_line_2_locs);
  }

  function getValidatorAddressLine2(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bytes32[] _validator_address_line_2) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));
    uint _validator_address_line_2_length = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_LINE_2)));
    bytes32[] memory _validator_address_line_2_locs = new bytes32[](_validator_address_line_2_length);
    for (uint i = 0; i < _validator_address_line_2_length; i++) {
      _validator_address_line_2_locs[i] = bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_LINE_2));
    } 
    _validator_address_line_2 = GetterInterface(_storage).readMulti(_exec_id, _validator_address_line_2_locs);
  }

  function getValidatorCity(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bytes32[] _validator_city) {
    require(_storage != address(0) && _exec_id != bytes32(0) && _validator != address(0));
    uint _validator_city_length = uint(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_ADDRESS_CITY)));
    bytes32[] memory _validator_city_locs = new bytes32[](_validator_city_length);
    for (uint i = 0; i < _validator_city_length; i++) {
      _validator_city_locs[i] = bytes32((32 * (i + 1)) + uint(VALIDATOR_ADDRESS_CITY));
    } 
    _validator_city = GetterInterface(_storage).readMulti(_exec_id, _validator_city_locs);
  }

  function getValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, VALIDATORS));
  }

  function getPendingValidatorCount(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, PENDING_VALIDATORS));
  }

  function isInitialKeyCeremonyCompleted(
    address _storage,
    bytes32 _exec_id
  ) external view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return bytes32(GetterInterface(_storage).read(_exec_id, COMPLETED_INITIAL_KEY_CEREMONY)) == bytes32(1);
  }

  function isValidator(
    address _storage, 
    bytes32 _exec_id,
    address _validator
  ) public view returns (bool) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return bytes32(GetterInterface(_storage).read(_exec_id, keccak256(_validator, VALIDATOR_IS_VALIDATOR))) == bytes32(1);
  }

  function getValidatorSupportCount(
    address _storage, 
    bytes32 _exec_id,
    address _addr
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, keccak256(_addr, VALIDATOR_SUPPORT_COUNT)));
  }

  function getValidatorSupportDivisor(
    address _storage, 
    bytes32 _exec_id
  ) public view returns (uint) {
    require(_storage != address(0) && _exec_id != bytes32(0));
    return uint(GetterInterface(_storage).read(_exec_id, VALIDATOR_SUPPORT_DIVISOR));
  }
}
