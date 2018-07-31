pragma solidity ^0.4.23;

import './classes/validators/IValidatorConsole.sol';
import './classes/voting/IVotingConsole.sol';

interface IAura {

  function init(address) external;
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

  function getProposals(address _storage, bytes32 _exec_id) external view returns (address[]);
  function getProposalsCount(address _storage, bytes32 _exec_id) external view returns (uint);


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
