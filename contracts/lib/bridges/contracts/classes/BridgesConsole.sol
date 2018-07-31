pragma solidity ^0.4.23;

import '../../../auth_os.sol';

library BridgesConsole {
  using Contract for *;

  bytes32 internal constant BRIDGES = keccak256("bridges");

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /*
  Add a bridge.
  @param _validator: The validator address to add
  @param _index: The index at which the validator will exist in the validators list
  @return store_data: A formatted storage request
  */
  function addBridge() public pure
  returns (bytes memory store_data) {
      // TODO-- this is a placeholder, for now
  }
}
