pragma solidity ^0.4.23;

import './classes/validators/IValidatorConsole.sol';
import './classes/voting/IVotingConsole.sol';

interface IAura {
  function getFinalized() external view returns (bool);
  function getMaximumValidatorCount() external view returns (uint);
  function getValidatorSupportCount(address) external view returns (uint);
  function getMinimumValidatorCount() external view returns (uint);
  function getValidator(address) external view returns (uint, address, address, address, bool );
  function getValidatorMetadata(address) external view returns(bytes32[], bytes32[], bytes32[], bytes32[], bytes32[], bytes32, bytes32, bytes32, bytes32);
  function getValidatorSupportDivisor() external view returns (uint);
  function getValidators() external view returns (address[]);
  function getPendingValidators() external view returns (address[]);
  function getValidatorIndex(address) external view returns (uint);
  function getValidatorName(address) external view returns (bytes32[]);
  function getValidatorEmail(address) external view returns (bytes32[]);
  function getValidatorAddressLine1(address) external view returns (bytes32[]);
  function getValidatorAddressLine2(address) external view returns (bytes32[]);
  function getValidatorCity(address) external view returns (bytes32[]);
  function getValidatorCount() external view returns (uint);
  function getPendingValidatorCount() external view returns (uint);
  function isInitialKeyCeremonyCompleted() external view returns (bool);
  function isValidator(address) external view returns (bool);
}

interface IAuraIdx {
  function getFinalized(address, bytes32) external view returns (bool);
  function getMaximumValidatorCount(address, bytes32) external view returns (uint);
  function getValidatorSupportCount(address, bytes32, address) external view returns (uint);
  function getMinimumValidatorCount(address, bytes32) external view returns (uint);
  function getValidator(address, bytes32, address) external view returns (uint, address, address, address, bool );
  function getValidatorMetadata(address, bytes32, address) external view returns(bytes32[], bytes32[], bytes32[], bytes32[], bytes32[], bytes32, bytes32, bytes32, bytes32);
  function getValidatorSupportDivisor(address, bytes32) external view returns (uint);
  function getValidators(address, bytes32) external view returns (address[]);
  function getPendingValidators(address, bytes32) external view returns (address[]);
  function getValidatorIndex(address, bytes32, address) external view returns (uint);
  function getValidatorName(address, bytes32, address) external view returns (bytes32[]);
  function getValidatorEmail(address, bytes32, address) external view returns (bytes32[]);
  function getValidatorAddressLine1(address, bytes32, address) external view returns (bytes32[]);
  function getValidatorAddressLine2(address, bytes32, address) external view returns (bytes32[]);
  function getValidatorCity(address, bytes32, address) external view returns (bytes32[]);
  function getValidatorCount(address, bytes32) external view returns (uint);
  function getPendingValidatorCount(address, bytes32) external view returns (uint);
  function isInitialKeyCeremonyCompleted(address, bytes32) external view returns (bool);
  function isValidator(address, bytes32, address) external view returns (bool);
}
