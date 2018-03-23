pragma solidity ^0.4.23;

import '../../auth_os.sol';

library OraclesConsole {
  using LibEvents for uint;
  using LibPayments for uint;
  using LibStorage for uint;
  using MemoryBuffers for uint;
  using Pointers for *; 

  bytes32 internal constant ORACLES = keccak256("oracles");

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /*
  Add an oracle to an existing bridge.
  @param _leftSide: The network identifier of the left side of the bridge (home chain)
  @param _rightSide: The network identifier on the ritht side of the bridge (foreign chain)
  @param _rightSide: The index at which the validator will exist in the validators list
  @return store_data: A formatted storage request
  */
  function addOracle() public pure
  returns (bytes memory store_data) {
      // TODO-- this is a placeholder, for now
  }
}
