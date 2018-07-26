pragma solidity ^0.4.23;

import '../../../auth_os.sol';

library InitBridges {
  using LibEvents for uint;
  using LibPayments for uint;
  using LibStorage for uint;
  using MemoryBuffers for uint;
  using Pointers for *; 

  // Bridges console

  function init() public pure returns (bytes memory store_data) {
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    store_data = ptr.toBuffer();
  }
}
