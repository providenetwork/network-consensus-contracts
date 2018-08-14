pragma solidity ^0.4.23;

interface IValidatorConsole {

  function addValidator(address _storage, bytes32 _exec_id, address _validator) external view;
}

interface ValidatorConsoleIdx {

}
