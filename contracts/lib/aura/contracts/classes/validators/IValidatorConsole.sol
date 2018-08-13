pragma solidity ^0.4.23;

interface IValidatorConsole {

  event ChangeFinalized(address[] validators);
  event InitiateChange(bytes32 indexed parent_hash, address[] validators);
  event InitializedRegistry(address indexed registry, bytes32 indexed registry_exec_id);
  event Report(address indexed validator, uint indexed block_number, bool indexed malicious, bytes proof);
  event Support(address indexed supporter, address indexed supported, bool indexed added);

  // function init(address) external;
  function addValidator(address _validator) external view;
  function getFinalized(address _storage, bytes32 _exec_id) external view returns (bool);
  function getMaximumValidatorCount(address _storage, bytes32 _exec_id) external view returns (uint);
  function getValidatorSupportCount(address _storage, bytes32 _exec_id, address _validator) external view returns (uint);
  function getMinimumValidatorCount(address _storage, bytes32 _exec_id) external view returns (uint);
  function getValidators(address _storage, bytes32 _exec_id) external view returns (address[]);
  function getPendingValidators(address _storage, bytes32 _exec_id) external view returns (address[]);
  function getValidatorIndex(address _storage, bytes32 _exec_id, address _validator) external view returns (uint _validator_index);
  function getValidatorName(address _storage, bytes32 _exec_id, address _validator) external view returns (bytes32[] _validator_name);
  function getValidatorEmail(address _storage, bytes32 _exec_id, address _validator) external view returns (bytes32[] _validator_email);
  function getValidatorAddressLine1(address _storage, bytes32 _exec_id, address _validator) external view returns (bytes32[] _validator_address_line_2);
  function getValidatorAddressLine2(address _storage, bytes32 _exec_id, address _validator) external view returns (bytes32[] _validator_address_line_2);
  function getValidatorCity(address _storage, bytes32 _exec_id,address _validator) external view returns (bytes32[] _validator_city);
  function getValidatorCount(address _storage, bytes32 _exec_id) external view returns (uint);
  function getPendingValidatorCount(address _storage, bytes32 _exec_id) external view returns (uint);
  function isInitialKeyCeremonyCompleted(address _storage, bytes32 _exec_id) external view returns (bool);
  function isValidator(address _storage, bytes32 _exec_id, address _validator) external view returns (bool);
  function getValidatorSupportDivisor(address _storage, bytes32 _exec_id) external view returns (uint);

  function getValidator(
    address _storage,
    bytes32 _exec_id,
    address _validator
  ) external view returns (uint _validator_index,
                         address _validator_sealing_key,
                         address _validator_payout_key,
                         address _validator_voting_key,
                         bool _is_validator);

  function getValidatorMetadata(
    address _storage,
    bytes32 _exec_id,
    address _validator
  ) external view returns(bytes32[] _validator_name,
                        bytes32[] _validator_email,
                        bytes32[] _validator_address_line_1,
                        bytes32[] _validator_address_line_2,
                        bytes32[] _validator_city,
                        bytes32 _validator_state,
                        bytes32 _validator_postal_code,
                        bytes32 _validator_country,
                        bytes32 _validator_phone);
}

interface ValidatorConsoleIdx {

}
