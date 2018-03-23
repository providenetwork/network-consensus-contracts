pragma solidity ^0.4.23;

// File: tmp/LibEvents.sol

library LibEvents {

  // ACTION REQUESTORS //

  bytes4 internal constant EMITS = bytes4(keccak256('emits:'));

  // Takes an existing or empty buffer stored at the buffer and adds an EMITS
  // requestor to the end
  function emits(uint _ptr) internal pure {
    bytes4 action_req = EMITS;
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push requestor to the of buffer
      mstore(add(_ptr, len), action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the EMITS action
      mstore(add(_ptr, add(0x04, len)), 0)
      // Increment buffer length
      mstore(_ptr, add(0x04, len))
      // Set a pointer to EMITS action length in the free slot before _ptr
      mstore(sub(_ptr, 0x20), add(_ptr, add(0x04, len)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x44, _ptr), len)) {
        mstore(0x40, add(add(0x44, _ptr), len))
      }
    }
  }

  function topics(uint _ptr) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push 0 to the end of the buffer - event will have no topics
      mstore(add(_ptr, len), 0)
      // Increment buffer length
      mstore(_ptr, len)
      // Increment EMITS action length (pointer to length stored before _ptr)
      let _len_ptr := mload(sub(_ptr, 0x20))
      mstore(_len_ptr, add(1, mload(_len_ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len))
      }
    }
    return _ptr;
  }

  function topics(uint _ptr, bytes32[1] memory _topics) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push 1 to the end of the buffer - event will have 1 topics
      mstore(add(_ptr, len), 1)
      // Push topic to end of buffer
      mstore(add(_ptr, add(0x20, len)), mload(_topics))
      // Increment buffer length
      mstore(_ptr, add(0x20, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x60, _ptr), len)) {
        mstore(0x40, add(add(0x60, _ptr), len))
      }
      // Increment EMITS action length (pointer to length stored before _ptr)
      len := mload(sub(_ptr, 0x20))
      mstore(len, add(1, mload(len)))
    }
    return _ptr;
  }

  function topics(uint _ptr, bytes32[2] memory _topics) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push 2 to the end of the buffer - event will have 2 topics
      mstore(add(_ptr, len), 2)
      // Push topics to end of buffer
      mstore(add(_ptr, add(0x20, len)), mload(_topics))
      mstore(add(_ptr, add(0x40, len)), mload(add(0x20, _topics)))
      // Increment buffer length
      mstore(_ptr, add(0x40, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x80, _ptr), len)) {
        mstore(0x40, add(add(0x80, _ptr), len))
      }
      // Increment EMITS action length (pointer to length stored before _ptr)
      len := mload(sub(_ptr, 0x20))
      mstore(len, add(1, mload(len)))
    }
    return _ptr;
  }

  function topics(uint _ptr, bytes32[3] memory _topics) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push 3 to the end of the buffer - event will have 3 topics
      mstore(add(_ptr, len), 3)
      // Push topics to end of buffer
      mstore(add(_ptr, add(0x20, len)), mload(_topics))
      mstore(add(_ptr, add(0x40, len)), mload(add(0x20, _topics)))
      mstore(add(_ptr, add(0x60, len)), mload(add(0x40, _topics)))
      // Increment buffer length
      mstore(_ptr, add(0x60, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0xa0, _ptr), len)) {
        mstore(0x40, add(add(0xa0, _ptr), len))
      }
      // Increment EMITS action length (pointer to length stored before _ptr)
      len := mload(sub(_ptr, 0x20))
      mstore(len, add(1, mload(len)))
    }
    return _ptr;
  }

  function topics(uint _ptr, bytes32[4] memory _topics) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push 4 to the end of the buffer - event will have 4 topics
      mstore(add(_ptr, len), 4)
      // Push topics to end of buffer
      mstore(add(_ptr, add(0x20, len)), mload(_topics))
      mstore(add(_ptr, add(0x40, len)), mload(add(0x20, _topics)))
      mstore(add(_ptr, add(0x60, len)), mload(add(0x40, _topics)))
      mstore(add(_ptr, add(0x80, len)), mload(add(0x60, _topics)))
      // Increment buffer length
      mstore(_ptr, add(0x80, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0xc0, _ptr), len)) {
        mstore(0x40, add(add(0xc0, _ptr), len))
      }
      // Increment EMITS action length (pointer to length stored before _ptr)
      len := mload(sub(_ptr, 0x20))
      mstore(len, add(1, mload(len)))
    }
    return _ptr;
  }

  function data(uint _ptr, bytes memory _data) internal pure returns (uint) {
    assembly {
      // Loop over bytes array, and push each value to storage buffer
      let offset := 0x0
      for { } lt(offset, add(0x20, mload(_data))) { offset := add(0x20, offset) } {
        // Push bytes array chunk to buffer
        mstore(add(add(add(0x20, mload(_ptr)), offset), _ptr), mload(add(offset, _data)))
      }
      // Increment buffer length
      mstore(_ptr, add(offset, mload(_ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), mload(_ptr))) {
        mstore(0x40, add(add(0x40, _ptr), mload(_ptr)))
      }
    }
    return _ptr;
  }

  function data(uint _ptr, bytes32 _data) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push data size (32 bytes) to end of buffer
      mstore(add(_ptr, len), 0x20)
      // Push value to the end of the buffer
      mstore(add(_ptr, add(0x20, len)), _data)
      // Increment buffer length
      mstore(_ptr, add(0x20, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x60, _ptr), len)) {
        mstore(0x40, add(add(0x60, _ptr), len))
      }
    }
    return _ptr;
  }

  function data(uint _ptr, uint _data) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push data size (32 bytes) to end of buffer
      mstore(add(_ptr, len), 0x20)
      // Push value to the end of the buffer
      mstore(add(_ptr, add(0x20, len)), _data)
      // Increment buffer length
      mstore(_ptr, add(0x20, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x60, _ptr), len)) {
        mstore(0x40, add(add(0x60, _ptr), len))
      }
    }
    return _ptr;
  }

  function data(uint _ptr, address _data) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push data size (32 bytes) to end of buffer
      mstore(add(_ptr, len), 0x20)
      // Push value to the end of the buffer
      mstore(add(_ptr, add(0x20, len)), _data)
      // Increment buffer length
      mstore(_ptr, add(0x20, len))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x60, _ptr), len)) {
        mstore(0x40, add(add(0x60, _ptr), len))
      }
    }
    return _ptr;
  }
}

// File: tmp/LibStorage.sol

library LibStorage {

  // ACTION REQUESTORS //

  bytes4 internal constant STORES = bytes4(keccak256('stores:'));

  // Set up a STORES action request buffer
  function stores(uint _ptr) internal pure {
    bytes4 action_req = STORES;
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push requestor to the of buffer
      mstore(add(_ptr, len), action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the STORES action
      mstore(add(_ptr, add(0x04, len)), 0)
      // Increment buffer length
      mstore(_ptr, add(0x04, len))
      // Set a pointer to STORES action length in the free slot before _ptr
      mstore(sub(_ptr, 0x20), add(_ptr, add(0x04, len)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x44, _ptr), len)) {
        mstore(0x40, add(add(0x44, _ptr), len))
      }
    }
  }

  function store(uint _ptr, bytes32 _val) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to the end of the buffer
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // Increment STORES action length (pointer to length stored before _ptr)
      let _len_ptr := mload(sub(_ptr, 0x20))
      mstore(_len_ptr, add(1, mload(_len_ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len))
      }
    }
    return _ptr;
  }

  function store(uint _ptr, address _val) internal pure returns (uint) {
    return store(_ptr, bytes32(_val));
  }

  function store(uint _ptr, uint _val) internal pure returns (uint) {
    return store(_ptr, bytes32(_val));
  }

  function store(uint _ptr, bool _val) internal pure returns (uint) {
    return store(
      _ptr,
      _val ? bytes32(1) : bytes32(0)
    );
  }

  function at(uint _ptr, bytes32 _loc) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push storage location to the end of the buffer
      mstore(add(_ptr, len), _loc)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len))
      }
    }
    return _ptr;
  }

  function storeBytesAt(uint _ptr, bytes memory _arr, bytes32 _base_location) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Loop over bytes array, and push each value and incremented storage location to storage buffer
      let offset := 0x0
      for { } lt(offset, add(0x20, mload(_arr))) { offset := add(0x20, offset) } {
        // Push incremented location to buffer
        mstore(add(add(add(0x20, len), mul(2, offset)), _ptr), add(offset, _base_location))
        // Push bytes array chunk to buffer
        mstore(add(add(len, mul(2, offset)), _ptr), mload(add(offset, _arr)))
      }
      // Increment buffer length
      mstore(_ptr, add(mul(2, offset), mload(_ptr)))
      // Increment STORES length
      let _len_ptr := mload(sub(_ptr, 0x20))
      len := add(div(offset, 0x20), mload(_len_ptr))
      mstore(_len_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), mload(_ptr))) {
        mstore(0x40, add(add(0x40, _ptr), mload(_ptr)))
      }
    }
    return _ptr;
  }
}

// File: tmp/Pointers.sol

library Pointers {

  function toBuffer(uint _ptr) internal pure returns (bytes memory buffer) {
    assembly {
      buffer := _ptr
    }
  }

  function toPointer(bytes memory _buffer) internal pure returns (uint _ptr) {
    assembly {
      _ptr := _buffer
    }
  }

  function clear(uint _ptr) internal pure returns (uint) {
    assembly {
      _ptr := add(0x20, msize)
      mstore(_ptr, 0)
      mstore(0x40, add(0x20, _ptr))
    }
    return _ptr;
  }

  function end(uint _ptr) internal pure returns (uint buffer_end) {
    assembly {
      let len := mload(_ptr)
      buffer_end := add(0x20, add(len, _ptr))
    }
  }
}

// File: tmp/AppConsole.sol

library AppConsole {

  using Pointers for *;
  using LibEvents for uint;
  using LibStorage for uint;

  /// PROVIDER STORAGE ///

  // Provider namespace - all app and version storage is seeded to a provider
  // [PROVIDERS][provider_id]
  bytes32 internal constant PROVIDERS = keccak256("registry_providers");

  // Storage location for a list of all applications released by this provider
  // [PROVIDERS][provider_id][PROVIDER_APP_LIST] = bytes32[] registered_apps
  bytes32 internal constant PROVIDER_APP_LIST = keccak256("provider_app_list");

  /// APPLICATION STORAGE ///

  // Application namespace - all app info and version storage is mapped here
  // [PROVIDERS][provider_id][APPS][app_name]
  bytes32 internal constant APPS = keccak256("apps");

  // Application description location - (bytes array)
  // [PROVIDERS][provider_id][APPS][app_name][APP_DESC] = bytes description
  bytes32 internal constant APP_DESC = keccak256("app_desc");

  // Application storage address location - address
  // [PROVIDERS][provider_id][APPS][app_name][APP_STORAGE_IMPL] = address app_default_storage_addr
  bytes32 internal constant APP_STORAGE_IMPL = keccak256("app_storage_impl");

  /// EVENT TOPICS ///

  // event AppRegistered(bytes32 indexed execution_id, bytes32 indexed provider_id, bytes32 app_name);
  bytes32 internal constant APP_REGISTERED = keccak256("AppRegistered(bytes32,bytes32,bytes32)");

  /// FUNCTION SELECTORS ///

  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /// FUNCTIONS ///

  /*
  Registers an application under the sender's provider id

  @param _app_name: The name of the application to be registered
  @param _app_storage: The storage address this application will use
  @param _app_desc: The description of the application (recommended: GitHub link)
  @param _context: The execution context for this application - a 96-byte array containing (in order):
    1. Application execution id
    2. Original script sender (address, padded to 32 bytes)
    3. Wei amount sent with transaction to storage
  @return bytes: A formatted bytes array that will be parsed by storage to emit events, forward payment, and store data
  */
  function registerApp(bytes32 _app_name, address _app_storage, bytes _app_desc, bytes memory _context) public view
  returns (bytes memory) {
    // Ensure input is correctly formatted
    require(_context.length == 96);
    require(_app_name != bytes32(0) && _app_desc.length > 0 && _app_storage != address(0));

    bytes32 exec_id;
    bytes32 provider;

    // Parse context array and get execution id and provider
    (exec_id, provider, ) = parse(_context);

    /// Ensure application is not already registered under this provider -

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Place exec id, data read offset, and read size to calldata
    cdPush(ptr, exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 2);
    // Place app storage location, and provider app list length in calldata
    bytes32 temp = keccak256(keccak256(provider), PROVIDERS); // Use a temporary var to get provider storage location
    cdPush(ptr, keccak256(keccak256(_app_name), keccak256(APPS, temp))); // Push application storage location to buffer
    cdPush(ptr, keccak256(PROVIDER_APP_LIST, temp)); // Push provider app list locaiton to calldata
    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMulti(ptr);
    // Check returned app storage location - if nonzero, application is already registered
    if (read_values[0] != bytes32(0))
      triggerException(bytes32("InsufficientPermissions"));

    // Get returned provider app list length
    uint num_apps = uint(read_values[1]);

    /// Application is unregistered - register application -

    // Get pointer to free memory
    ptr = ptr.clear();

    // Set up STORES action requests -
    ptr.stores();
    // Push each storage location and value to the STORES request buffer:

    // Store app name in app base storage location
    temp = keccak256(keccak256(_app_name), keccak256(APPS, temp));
    ptr.store(_app_name).at(temp);

    // Store app default storage address in APP_STORAGE_IMPL location
    ptr.store(_app_storage).at(keccak256(APP_STORAGE_IMPL, temp));

    // Increment provider app list length
    temp = keccak256(keccak256(provider), PROVIDERS);
    temp = keccak256(PROVIDER_APP_LIST, temp);
    ptr.store(1 + num_apps).at(temp);

    // Push app name to the end of the provider's app list
    ptr.store(_app_name).at(bytes32(32 + 32 * num_apps + uint(temp)));

    // Push description bytes to APP_DESC storage location
    temp = keccak256(keccak256(provider), PROVIDERS);
    temp = keccak256(keccak256(_app_name), keccak256(APPS, temp));
    temp = keccak256(APP_DESC, temp);
    ptr.storeBytesAt(_app_desc, temp);

    // Set up EMITS action requests -
    ptr.emits();

    // Add APP_REGISTERED event topics and data (app name)
    ptr.topics(
      [APP_REGISTERED, exec_id, keccak256(provider)]
    ).data(_app_name);

    // Return formatted action requests to storage
    return ptr.toBuffer();
  }

  /*
  Creates a calldata buffer in memory with the given function selector

  @param _selector: The function selector to push to the first location in the buffer
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function cdBuff(bytes4 _selector) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Place initial length (4 bytes) in buffer
      mstore(ptr, 0x04)
      // Place function selector in buffer, after length
      mstore(add(0x20, ptr), _selector)
      // Update free-memory pointer - it's important to note that this is not actually free memory, if the pointer is meant to expand
      mstore(0x40, add(0x40, ptr))
    }
  }

  /*
  Pushes a value to the end of a calldata buffer, and updates the length

  @param _ptr: A pointer to the start of the buffer
  @param _val: The value to push to the buffer
  */
  function cdPush(uint _ptr, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to end of buffer (overwrites memory - be careful!)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x2c, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return read_values: The values read from storage
  */
  function readMulti(uint _ptr) internal view returns (bytes32[] memory read_values) {
    bool success;
    assembly {
      // Minimum length for 'readMulti' - 1 location is 0x84
      if lt(mload(_ptr), 0x84) { revert (0, 0) }
      // Read from storage
      success := staticcall(gas, caller, add(0x20, _ptr), mload(_ptr), 0, 0)
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Reverts state changes, but passes message back to caller

  @param _message: The message to return to the caller
  */
  function triggerException(bytes32 _message) internal pure {
    assembly {
      mstore(0, _message)
      revert(0, 0x20)
    }
  }


  // Parses context array and returns execution id, provider, and sent wei amount
  function parse(bytes memory _context) internal pure returns (bytes32 exec_id, bytes32 provider, uint wei_sent) {
    assembly {
      exec_id := mload(add(0x20, _context))
      provider := mload(add(0x40, _context))
      wei_sent := mload(add(0x60, _context))
    }
    // Ensure sender and exec id are valid
    if (provider == bytes32(0) || exec_id == bytes32(0))
      triggerException(bytes32("UnknownContext"));
  }
}

// File: tmp/ImplementationConsole.sol

library ImplementationConsole {

  using Pointers for *;
  using LibEvents for uint;
  using LibStorage for uint;

  /// PROVIDER STORAGE ///

  // Provider namespace - all app and version storage is seeded to a provider
  // [PROVIDERS][provider_id]
  bytes32 internal constant PROVIDERS = keccak256("registry_providers");

  /// APPLICATION STORAGE ///

  // Application namespace - all app info and version storage is mapped here
  // [PROVIDERS][provider_id][APPS][app_name]
  bytes32 internal constant APPS = keccak256("apps");

  /// VERSION STORAGE ///

  // Version namespace - all version and function info is mapped here
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS]
  bytes32 internal constant VERSIONS = keccak256("versions");

  // Version "is finalized" location - whether a version is ready for use (all intended functions implemented)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_IS_FINALIZED] = bool is_finalized
  bytes32 internal constant VER_IS_FINALIZED = keccak256("ver_is_finalized");

  // Version function list location - (bytes4 array)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_FUNCTION_LIST] = bytes4[] function_signatures
  bytes32 internal constant VER_FUNCTION_LIST = keccak256("ver_functions_list");

  // Version function address location - stores the address where each corresponding version's function is located
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_FUNCTION_ADDRESSES] = address[] function_addresses
  bytes32 internal constant VER_FUNCTION_ADDRESSES = keccak256("ver_function_addrs");

  /// FUNCTION SELECTORS ///

  // Function selector for storage 'readMulti'
  // readMulti(bytes32 exec_id, bytes32[] locations)
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /// FUNCTIONS ///

  /*
  Adds functions and their implementing addresses to a non-finalized version

  @param _app: The name of the application under which the version is registered
  @param _version: The name of the version to add functions to
  @param _function_sigs: An array of function selectors the version will implement
  @param _function_addrs: The corresponding addresses which implement the given functions
  @param _context: The execution context for this application - a 96-byte array containing (in order):
    1. Application execution id
    2. Original script sender (address, padded to 32 bytes)
    3. Wei amount sent with transaction to storage
  @return bytes: A formatted bytes array that will be parsed by storage to emit events, forward payment, and store data
  */
  function addFunctions(bytes32 _app, bytes32 _version, bytes4[] memory _function_sigs, address[] memory _function_addrs, bytes memory _context) public view
  returns (bytes memory) {
    // Ensure input is correctly formatted
    require(_context.length == 96);
    require(_app != bytes32(0) && _version != bytes32(0));
    require(_function_sigs.length == _function_addrs.length && _function_sigs.length > 0);

    bytes32 exec_id;
    bytes32 provider;

    // Parse context array and get provider and execution id
    (exec_id, provider, ) = parse(_context);

    // Get app base storage location -
    bytes32 temp = keccak256(keccak256(provider), PROVIDERS);
    temp = keccak256(keccak256(_app), keccak256(APPS, temp));

    /// Ensure application and version are registered, and version is not finalized
    /// Additionally, read version function and address list lengths -

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Place exec id, data read offset, and read size to calldata
    cdPush(ptr, exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 5);
    // Push app base storage, version base storage, and version finalization status storage locations to buffer
    cdPush(ptr, temp);
    // Get version base storage -
    temp = keccak256(keccak256(_version), keccak256(VERSIONS, temp));
    cdPush(ptr, temp);
    cdPush(ptr, keccak256(VER_IS_FINALIZED, temp));
    // Push version function and address list length storage locations to calldata
    cdPush(ptr, keccak256(VER_FUNCTION_LIST, temp));
    cdPush(ptr, keccak256(VER_FUNCTION_ADDRESSES, temp));

    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMulti(ptr);
    // Check returned values
    if (
      read_values[0] == bytes32(0) // Application does not exist
      || read_values[1] == bytes32(0) // Version does not exist
      || read_values[2] != bytes32(0) // Version is already finalized
    ) {
      triggerException(bytes32("InsufficientPermissions"));
    }
    // Version function selector and address lists should always be equal
    assert(read_values[3] == read_values[4]);
    // Get version function and address list lengths
    uint list_lengths = uint(read_values[3]);

    /// App and version are registered, and version has not been finalized - store function information

    // Get pointer to free memory
    ptr = ptr.clear();

    // Set up STORES action requests -
    ptr.stores();
    // Push each storage location and value to the STORES request buffer:

    // Store new version list lengths
    ptr.store(
      list_lengths + _function_sigs.length
    ).at(keccak256(VER_FUNCTION_LIST, temp));
    ptr.store(
      list_lengths + _function_sigs.length
    ).at(keccak256(VER_FUNCTION_ADDRESSES, temp));

    // Loop through functions and addresses and push each to the end of their respective lists
    for (uint i = list_lengths; i < _function_sigs.length + list_lengths; i++) {
      // Push function selector to the end of the version function list
      ptr.store(
        _function_sigs[i - list_lengths]
      ).at(bytes32(32 + (i * 32) + uint(keccak256(VER_FUNCTION_LIST, temp))));
      // Push function implementing address to the end of the version address list
      ptr.store(
        _function_addrs[i - list_lengths]
      ).at(bytes32(32 + (i * 32) + uint(keccak256(VER_FUNCTION_ADDRESSES, temp))));
    }

    // Return formatted action requests to storage
    return ptr.toBuffer();
  }

  /*
  Creates a calldata buffer in memory with the given function selector

  @param _selector: The function selector to push to the first location in the buffer
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function cdBuff(bytes4 _selector) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Place initial length (4 bytes) in buffer
      mstore(ptr, 0x04)
      // Place function selector in buffer, after length
      mstore(add(0x20, ptr), _selector)
      // Update free-memory pointer - it's important to note that this is not actually free memory, if the pointer is meant to expand
      mstore(0x40, add(0x40, ptr))
    }
  }

  /*
  Pushes a value to the end of a calldata buffer, and updates the length

  @param _ptr: A pointer to the start of the buffer
  @param _val: The value to push to the buffer
  */
  function cdPush(uint _ptr, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to end of buffer (overwrites memory - be careful!)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x2c, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return read_values: The values read from storage
  */
  function readMulti(uint _ptr) internal view returns (bytes32[] memory read_values) {
    bool success;
    assembly {
      // Minimum length for 'readMulti' - 1 location is 0x84
      if lt(mload(_ptr), 0x84) { revert (0, 0) }
      // Read from storage
      success := staticcall(gas, caller, add(0x20, _ptr), mload(_ptr), 0, 0)
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Reverts state changes, but passes message back to caller

  @param _message: The message to return to the caller
  */
  function triggerException(bytes32 _message) internal pure {
    assembly {
      mstore(0, _message)
      revert(0, 0x20)
    }
  }


  // Parses context array and returns execution id, provider, and sent wei amount
  function parse(bytes memory _context) internal pure returns (bytes32 exec_id, bytes32 provider, uint wei_sent) {
    assembly {
      exec_id := mload(add(0x20, _context))
      provider := mload(add(0x40, _context))
      wei_sent := mload(add(0x60, _context))
    }
    // Ensure sender and exec id are valid
    if (provider == bytes32(0) || exec_id == bytes32(0))
      triggerException(bytes32("UnknownContext"));
  }
}

// File: tmp/Exceptions.sol

library Exceptions {

  /*
  Reverts state changes, but passes message back to caller

  @param _message: The message to return to the caller
  */
  function trigger(bytes32 _message) internal pure {
    assembly {
      mstore(0, _message)
      revert(0, 0x20)
    }
  }

}

// File: tmp/MemoryBuffers.sol

library MemoryBuffers {

  using Exceptions for bytes32;

  bytes32 internal constant ERR_READ_FAILED = bytes32("StorageReadFailed"); // Read from storage address failed

  /// CALLDATA BUFFERS ///

  /*
  Creates a calldata buffer in memory with the given function selector

  @param _selector: The function selector to push to the first location in the buffer
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function cdBuff(bytes4 _selector) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Place initial length (4 bytes) in buffer
      mstore(ptr, 0x04)
      // Place function selector in buffer, after length
      mstore(add(0x20, ptr), _selector)
      // Update free-memory pointer - it's important to note that this is not actually free memory, if the pointer is meant to expand
      mstore(0x40, add(0x40, ptr))
    }
  }

  /*
  Creates a new calldata buffer at the pointer with the given selector. Does not update free memory

  @param _ptr: A pointer to the buffer to overwrite - will be the pointer to the new buffer as well
  @param _selector: The function selector to place in the buffer
  */
  function cdOverwrite(uint _ptr, bytes4 _selector) internal pure {
    assembly {
      // Store initial length of buffer - 4 bytes
      mstore(_ptr, 0x04)
      // Store function selector after length
      mstore(add(0x20, _ptr), _selector)
    }
  }

  /*
  Pushes a value to the end of a calldata buffer, and updates the length

  @param _ptr: A pointer to the start of the buffer
  @param _val: The value to push to the buffer
  */
  function cdPush(uint _ptr, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to end of buffer (overwrites memory - be careful!)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x2c, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return read_values: The values read from storage
  */
  function readMulti(uint _ptr) internal view returns (bytes32[] memory read_values) {
    bool success;
    assembly {
      // Minimum length for 'readMulti' - 1 location is 0x84
      if lt(mload(_ptr), 0x84) { revert (0, 0) }
      // Read from storage
      success := staticcall(gas, caller, add(0x20, _ptr), mload(_ptr), 0, 0)
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
    if (!success)
      ERR_READ_FAILED.trigger();
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The storage address from which to read
  @return read_values: The values read from storage
  */
  function readMultiFrom(uint _ptr, address _storage) internal view returns (bytes32[] memory read_values) {
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
    if (!success)
      ERR_READ_FAILED.trigger();
  }

  /*
  Executes a 'read' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return read_value: The value read from storage
  */
  function readSingle(uint _ptr) internal view returns (bytes32 read_value) {
    bool success;
    assembly {
      // Length for 'read' buffer must be 0x44
      if iszero(eq(mload(_ptr), 0x44)) { revert (0, 0) }
      // Read from storage, and store return to pointer
      success := staticcall(gas, caller, add(0x20, _ptr), mload(_ptr), _ptr, 0x20)
      // If call succeeded, store return at pointer
      if gt(success, 0) { read_value := mload(_ptr) }
    }
    if (!success)
      ERR_READ_FAILED.trigger();
  }

  /*
  Executes a 'read' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The storage address from which to read
  @return read_value: The value read from storage
  */
  function readSingleFrom(uint _ptr, address _storage) internal view returns (bytes32 read_value) {
    bool success;
    assembly {
      // Length for 'read' buffer must be 0x44
      if iszero(eq(mload(_ptr), 0x44)) { revert (0, 0) }
      // Read from storage, and store return to pointer
      success := staticcall(gas, _storage, add(0x20, _ptr), mload(_ptr), _ptr, 0x20)
      // If call succeeded, store return at pointer
      if gt(success, 0) { read_value := mload(_ptr) }
    }
    if (!success)
      ERR_READ_FAILED.trigger();
  }

  /// STORAGE BUFFERS ///

  /*
  Creates a buffer for return data storage. Buffer pointer stores the lngth of the buffer

  @param _spend_destination: The destination to which _wei_amount will be forwarded
  @param _wei_amount: The amount of wei to send to the destination
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function stBuff(address _spend_destination, uint _wei_amount) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Store initial buffer length
      mstore(ptr, 0x40)
      // Push spend destination and wei amount to buffer
      mstore(add(0x20, ptr), _spend_destination)
      mstore(add(0x40, ptr), _wei_amount)
      // Update free-memory pointer to point beyond the buffer
      mstore(0x40, add(0x60, ptr))
    }
  }

  /*
  Creates a new return data storage buffer at the position given by the pointer. Does not update free memory

  @param _ptr: A pointer to the location where the buffer will be created
  @param _spend_destination: The destination to which _wei_amount will be forwarded
  @param _wei_amount: The amount of wei to send to the destination
  */
  function stOverwrite(uint _ptr, address _spend_destination, uint _wei_amount) internal pure {
    assembly {
      // Set initial length
      mstore(_ptr, 0x40)
      // Push spend destination and wei amount to buffer
      mstore(add(0x20, _ptr), _spend_destination)
      mstore(add(0x40, _ptr), _wei_amount)
      // Update free-memory pointer to point beyond the buffer
      mstore(0x40, msize)
    }
  }

  /*
  Pushes a storage location and value to the end of the storage buffer, and updates the buffer length

  @param _ptr: A pointer to the start of the buffer
  @param _location: The location to which the value will be written
  @param _val: The value to push to the buffer
  */
  function stPush(uint _ptr, bytes32 _location, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push location and value to end of buffer
      mstore(add(_ptr, len), _location)
      len := add(0x20, len)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Returns the bytes stored at the buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return store_data: The return values, which will be stored
  */
  function getBuffer(uint _ptr) internal pure returns (bytes memory store_data) {
    assembly {
      // If the size stored at the pointer is not evenly divislble into 32-byte segments, this was improperly constructed
      mstore(_ptr, div(mload(_ptr), 0x20))
      store_data := _ptr
    }
  }

  /*
  Returns the bytes32[] stored at the buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return store_data: The return values, which will be stored
  */
  function getBytes32Buffer(uint _ptr) internal pure returns (bytes32[] memory store_data) {
    assembly {
      // If the size stored at the pointer is not evenly divislble into 32-byte segments, this was improperly constructed
      if gt(mod(mload(_ptr), 0x20), 0) { revert (0, 0) }
      mstore(_ptr, div(mload(_ptr), 0x20))
      store_data := _ptr
    }
  }
}

// File: tmp/ScriptExec.sol

contract ScriptExec {

  /// DEFAULT APPLICATION SOURCES ///

  // Framework bootstrap method - admin is able to change executor script source and registry address
  address public exec_admin;

  // Framework bootstrap method - applications default to pulling application registry information from a single source
  address public default_storage;

  // Framework bootstrap method - applications default to allowing app updates from a single source
  address public default_updater;

  // Framework bootstrap method - applications default to pull information from a registry with this specified execution id
  bytes32 public default_registry_exec_id;

  // Framework bootstrap method - application init and implementation data is pulled from a single provider by default
  bytes32 public default_provider;

  // If the exec admin wants to suggest a new script exec contract to migrate to, this address is set to the new address
  address public new_script_exec;

  /// FUNCTION SELECTORS ///

  // Function selector for registry 'getAppLatestInfo' - returns information necessary for initialization
  bytes4 internal constant GET_LATEST_INFO = bytes4(keccak256("getAppLatestInfo(address,bytes32,bytes32,bytes32)"));

  // Function selector for abstract storage 'app_info' mapping - returns information on an exec id
  bytes4 internal constant GET_APP_INFO = bytes4(keccak256("app_info(bytes32)"));

  // Function selector for zero-arg application initializer
  bytes4 internal constant DEFAULT_INIT = bytes4(keccak256(("init()")));

  // Function selector for application storage 'initAndFinalize' - registers an application and returns a unique execution id
  bytes4 internal constant INIT_APP = bytes4(keccak256("initAndFinalize(address,bool,address,bytes,address[])"));

  // // Function selector for app storage "exec" - verifies sender and target address, then executes application
  bytes4 internal constant APP_EXEC = bytes4(keccak256("exec(address,bytes32,bytes)"));

  // Function selector for app storage "getExecAllowed" - retrieves the allowed addresses for a given application instance
  bytes4 internal constant GET_ALLOWED = bytes4(keccak256("getExecAllowed(bytes32)"));

  /// EVENTS ///

  // UPGRADING //

  event ApplicationMigration(address indexed storage_addr, bytes32 indexed exec_id, address new_exec_addr, address original_deployer);

  // EXCEPTION HANDLING //

  event StorageException(address indexed storage_addr, bytes32 indexed exec_id, address sender, uint wei_sent);
  event AppInstanceCreated(address indexed creator, bytes32 indexed exec_id, address storage_addr, bytes32 app_name, bytes32 version_name);

  struct AppInstance {
    address deployer;
    bytes32 app_name;
    bytes32 version_name;
  }

  struct ActiveInstance {
    bytes32 exec_id;
    bytes32 app_name;
    bytes32 version_name;
  }

  // Framework bootstrap method - keeps track of all deployed apps (through exec ids), and information on them
  // Maps app storage address -> app execution id -> AppInstance
  mapping (address => mapping (bytes32 => AppInstance)) public deployed_apps;
  mapping (address => bytes32[]) public exec_id_lists;

  // Maps a deployer to an array of applications they have deployed
  mapping (address => ActiveInstance[]) public deployer_instances;

  // Modifier - The sender must be the contract administrator
  modifier onlyAdmin() {
    require(msg.sender == exec_admin);
    _;
  }

  // Constructor - gives the sender administrative permissions and sets default registry and update sources
  constructor(address _exec_admin, address _update_source, address _registry_storage, bytes32 _app_provider_id) public {
    exec_admin = _exec_admin;
    default_updater = _update_source;
    default_storage = _registry_storage;
    default_provider = _app_provider_id;

    if (exec_admin == address(0)) {
      exec_admin = msg.sender;
    }
  }

  // Payable function - for abstract storage refunds
  function () public payable {
  }

  /// APPLICATION EXECUTION ///

  /*
  ** 2 pieces of information are needed to execute a function of an application
  ** instance - its storage address, and the unique execution id associated with
  ** it. Because this version of auth_os is in beta, this contract does not
  ** allow for app storage addresses outside of the set default, but does allow
  ** for this restriction to be removed in the future by setting the default to 0,
  ** or by using the registry's update functionality to migrate to a new script
  ** execution contract.
  */

  /*
  Executes an application using its execution id and storage address. For non-payable execution, specifies that all _app_calldata
  arrays must contain, in order, the app execution id, and the 32-byte padded sender's address. For payable execution, this should
  be followed by the value sent, in wei.

  @param _target: The target address, which houses the function being called
  @param _app_calldata: The calldata to forward to the application target address
  @return success: Whether execution succeeded or not
  @return returned_data: Data returned from app storage
  */
  function exec(address _target, bytes _app_calldata) public payable returns (bool success) {
    bytes32 exec_id;
    bytes32 exec_as;
    uint wei_sent;
    // Ensure execution id and provider make up the calldata's first 64 bytes, after the function selector
    // Ensure the next 32 bytes is equal to msg.value
    (exec_id, exec_as, wei_sent) = parse(_app_calldata);
    require(exec_as == bytes32(msg.sender) && wei_sent == msg.value);
    // Call target with calldata
    bytes memory calldata = abi.encodeWithSelector(APP_EXEC, _target, exec_id, _app_calldata);
    require(default_storage.call.value(msg.value)(calldata));

    // Get returned data
    success = checkReturn();
    // If execution failed, emit event
    if (!success)
      emit StorageException(default_storage, exec_id, msg.sender, msg.value);

    // Transfer any returned wei back to the sender
    address(msg.sender).transfer(address(this).balance);
  }

  function checkReturn() internal pure returns (bool success) {
    success = false;
    assembly {
      // returndata size must be 0x60 bytes
      if eq(returndatasize, 0x60) {
        // Copy returned data to pointer and check that at least one value is nonzero
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, returndatasize)
        if iszero(iszero(mload(ptr))) { success := 1 }
        if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
        if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
      }
    }
    return success;
  }

  /// APPLICATION INITIALIZATION ///

  struct AppInit {
    bytes4 get_init;
    bytes4 init_app;
    address registry_addr;
    bytes32 exec_id;
    bytes32 provider;
    address updater;
  }

  /*
  Initializes an instance of an application. Uses default app provider, script registry, app updater,
  and script registry exec id to get app information. Uses latest app version by default.

  @param _app: The name of the application to initialize
  @param _is_payable: Whether the app will accept ether
  @param _init_calldata: Calldata to be forwarded to an application's initialization function
  @return ver_name: The name of the most recent stable version of the application, which was used to register this app instance
  @return exec_id: The execution id (within the application's storage) of the created application instance
  */
  function initAppInstance(bytes32 _app, bool _is_payable, bytes _init_calldata) public returns (bytes32 ver_name, bytes32 app_exec_id) {
    // Ensure valid input
    require(_app != bytes32(0) && _init_calldata.length != 0);

    address init_registry;

    // Get registry application information from storage
    require(default_storage.call(abi.encodeWithSelector(GET_APP_INFO, default_registry_exec_id)), "app_info call failed");
    // Get init address from returned data
    assembly {
      // Check returndatasize - should be 0xc0 bytes
      if iszero(eq(returndatasize, 0xc0)) { revert (0, 0) }
      // Grab the last 32 bytes of returndata
      returndatacopy(0, sub(returndatasize, 0x20), 0x20)
      // Get InitRegistry address
      init_registry := mload(0)
    }
    // Ensure a valid registry init address
    require(init_registry != address(0), "Invalid registry init address");

    bytes memory calldata = abi.encodeWithSelector(
      GET_LATEST_INFO, default_storage, default_registry_exec_id,
      default_provider, _app
    );

    address app_init;
    address[] memory app_allowed;

    // Get information on latest version of application from InitRegistry
    assembly {
      // Set up staticcall to library
      let ret := staticcall(gas, init_registry, add(0x20, calldata), mload(calldata), 0, 0)
      // Ensure success
      if iszero(ret) { revert (0, 0) }
      // Check returndatasize - should be at least 0xc0 bytes
      if lt(returndatasize, 0xc0) { revert (0, 0) }

      // Copy returned data to free memory
      let ptr := mload(0x40)
      // (omitting app storage address in copy)
      returndatacopy(ptr, 0x20, sub(returndatasize, 0x20))
      // Update free memory pointer
      // Get version name from returned data
      ver_name := mload(ptr)
      // Get application init address from returned data
      app_init := mload(add(0x20, ptr))
      // Get app allowed addresses from returned data
      app_allowed := add(0x60, ptr)
      mstore(0x40, add(returndatasize, app_allowed))
    }
    // Ensure valid app init address, version name, and allowed address array
    require(ver_name != bytes32(0) && app_init != address(0) && app_allowed.length != 0, "invalid version info returned");

    // Call AbstractStorage.initAndFinalize
    require(default_storage.call(abi.encodeWithSelector(
      INIT_APP, default_updater, _is_payable, app_init, _init_calldata, app_allowed
    )), "initAndFinalize call failed");
    // Get returned execution id from calldata
    assembly {
      // Returned data should be 0x20 bytes
      if iszero(eq(returndatasize, 0x20)) { revert (0, 0) }
      // Copy returned data to memory
      returndatacopy(0, 0, 0x20)
      // Get returned execution id
      app_exec_id := mload(0)
    }
    // Ensure valid returned execution id
    require(app_exec_id != bytes32(0), "invalid exec id returned");

    // Emit event
    emit AppInstanceCreated(msg.sender, app_exec_id, default_storage, _app, ver_name);

    deployed_apps[default_storage][app_exec_id] = AppInstance({
      deployer: msg.sender,
      app_name: _app,
      version_name: ver_name
    });

    exec_id_lists[default_storage].push(app_exec_id);

    deployer_instances[msg.sender].push(ActiveInstance({
      exec_id: app_exec_id,
      app_name: _app,
      version_name: ver_name
    }));
  }

  /// STORAGE GETTERS ///

  function getAppAllowed(bytes32 _exec_id) public view returns (address[] allowed) {
    address _storage = default_storage;
    // Place 'getExecAllowed' function selector in memory
    bytes4 exec_allowed = GET_ALLOWED;
    assembly {
      // Get pointer to free memory for calldata
      let ptr := mload(0x40)
      // Store function selector and exec id in calldata
      mstore(ptr, exec_allowed)
      mstore(add(0x04, ptr), _exec_id)
      // Read from storage
      let ret := staticcall(gas, _storage, ptr, 0x24, 0, 0)
      // Allocate space for return, and copy returned data
      allowed := add(0x20, msize)
      returndatacopy(allowed, 0x20, sub(returndatasize, 0x20))
    }
  }

  /// INSTANCE DEPLOYER ///

  // Allows the deployer of an application instance to migrate to a new script exec contract, if the exec admin has provided one to migrate to
  function migrateApplication(bytes32 _exec_id) public {
    // Ensure sender is the app deployer
    require(deployed_apps[default_storage][_exec_id].deployer == msg.sender);
    // Ensure new script exec address has been set
    require(new_script_exec != address(0));

    // Call abstract storage and migrate the exec id
    bytes4 change_selector = bytes4(keccak256("changeScriptExec(bytes32,address)"));
    require(default_storage.call(change_selector, _exec_id, new_script_exec));

    // Emit event
    emit ApplicationMigration(default_storage, _exec_id, new_script_exec, msg.sender);
  }

  /// ADMIN ///

  // Allows the admin to suggest a new script exec contract, which instance deployers can then migrate to
  function changeExec(address _new_exec) public onlyAdmin() {
    new_script_exec = _new_exec;
  }

  // Allows the admin to change the registry storage for application registry
  function changeStorage(address _new_storage) public onlyAdmin() {
    default_storage = _new_storage;
  }

  // Allows the admin to change the default update address for applications
  function changeUpdater(address _new_updater) public onlyAdmin() {
    default_updater = _new_updater;
  }

  // Allows the admin to transfer permissions to a new address
  function changeAdmin(address _new_admin) public onlyAdmin() {
    exec_admin = _new_admin;
  }

  // Allows the admin to change the default provider information to pull application implementation details from
  function changeProvider(bytes32 _new_provider) public onlyAdmin() {
    default_provider = _new_provider;
  }

  // Allows the admin to change the default execution id used to interact with the registry application
  function changeRegistryExecId(bytes32 _new_id) public onlyAdmin() {
    default_registry_exec_id = _new_id;
  }

  /// HELPERS ///

  // Parses payable app calldata and returns app exec id, sender address, and wei sent
  function parse(bytes _app_calldata) internal pure returns (bytes32 exec_id, bytes32 exec_as, uint wei_sent) {
    assembly {
      exec_id := mload(sub(add(_app_calldata, mload(_app_calldata)), 0x40))
      exec_as := mload(sub(add(_app_calldata, mload(_app_calldata)), 0x20))
      wei_sent := mload(add(_app_calldata, mload(_app_calldata)))
    }
  }
}

// File: tmp/RegistryExec.sol

contract RegistryExec is ScriptExec {

  /// FUNCTION SELECTORS ///

  // Function selector for zero-arg application initializer
  bytes4 internal constant DEFAULT_INIT = bytes4(keccak256(("init()")));

  // Function selector for app console "registerApp"
  bytes4 internal constant REGISTER_APP = bytes4(keccak256("registerApp(bytes32,address,bytes,bytes)"));

  // Function selector for version console "registerVersion"
  bytes4 internal constant REGISTER_VERSION = bytes4(keccak256("registerVersion(bytes32,bytes32,address,bytes,bytes)"));

  // Function selector for implementation console "addFunctions"
  bytes4 internal constant ADD_FUNCTIONS = bytes4(keccak256("addFunctions(bytes32,bytes32,bytes4[],address[],bytes)"));

  // Function selector for version console "finalizeVersion"
  bytes4 internal constant FINALIZE_VERSION = bytes4(keccak256("finalizeVersion(bytes32,bytes32,address,bytes4,bytes,bytes)"));

  /// REGISTRIES ///

  struct Registry {
    address init;
    address app_console;
    address version_console;
    address implementation_console;
    bytes32 exec_id;
    // TODO: consider adding additional registry meta, such as name, github repo etc
  }

  // Map of execution ids to registry metadata
  mapping (bytes32 => Registry) public registries;

  constructor(address _exec_admin, address _update_source, address _registry_storage, bytes32 _app_provider)
    ScriptExec(_exec_admin, _update_source, _registry_storage, _app_provider) public
  {}

  /// REGISTRY BOOTSTRAP ///

  function initRegistry(address _init, address _app_console, address _version_console, address _impl_console) public onlyAdmin() returns (bytes32 exec_id) {
    require(_init != address(0) && _app_console != address(0) && _version_console != address(0) && _impl_console != address(0));
    require(default_storage != address(0) && default_updater != address(0));

    bytes4 _init_sel = INIT_APP;
    bytes4 _registry_init_sel = DEFAULT_INIT;

    address _registry_storage = default_storage;
    address _registry_updater = default_updater;

    address[3] memory _allowed = [_app_console, _version_console, _impl_console];

    assembly {
      let _ptr := mload(0x40)
      mstore(_ptr, _init_sel)
      mstore(add(0x04, _ptr), _registry_updater)
      mstore(add(0x24, _ptr), 0x0)
      mstore(add(0x44, _ptr), _init)

      // setup data read offsets...
      mstore(add(0x64, _ptr), 0xa0)
      mstore(add(0x84, _ptr), 0xe0)

      mstore(add(0xa4, _ptr), 0x04)
      mstore(add(0xc4, _ptr), _registry_init_sel)

      mstore(add(0xe4, _ptr), 0x03)

      let _offset := 0x0
      for { } lt(_offset, 0x60) { _offset := add(0x20, _offset) } {
        mstore(add(add(0x104, _offset), _ptr), mload(add(_offset, _allowed)))
      }

      let _ret := call(gas, _registry_storage, 0, _ptr, add(0x104, _offset), _ptr, 0x20)
      if iszero(_ret) { revert (0, 0) }
      exec_id := mload(_ptr)
    }

    if (default_registry_exec_id == bytes32(0)) {
      default_registry_exec_id = exec_id;
    }

    require(exec_id != bytes32(0));
    registries[exec_id] = Registry({
      exec_id: exec_id,
      init: _init,
      app_console: _app_console,
      version_console: _version_console,
      implementation_console: _impl_console
    });
  }

  function registerApp(bytes32 _app_name, bytes memory _app_description) public onlyAdmin() {
    require(_app_name != bytes32(0) && _app_description.length != 0);
    require(default_storage != address(0) && default_registry_exec_id != bytes32(0) && default_provider != bytes32(0) && default_updater != address(0));

    bytes4 _registry_exec_sel = APP_EXEC;
    bytes4 _register_app_sel = REGISTER_APP;

    address _registry_storage = default_storage;
    address _app_console = registries[default_registry_exec_id].app_console;
    require(_app_console != address(0));

    bytes32 _registry_exec_id = default_registry_exec_id;
    bytes memory _ctx = buildContext(_registry_exec_id, bytes32(msg.sender), 0);

    assembly {
      let _normalized_desc_len := mload(_app_description)
      if gt(mod(_normalized_desc_len, 0x20), 0) {
        _normalized_desc_len := sub(add(_normalized_desc_len, 0x20), mod(_normalized_desc_len, 0x20))
      }

      let _ptr_length := sub(add(add(0x128, add(0x20, _normalized_desc_len)), 0x80), 0x04)
      let _ptr := mload(0x40)
      mstore(_ptr, _registry_exec_sel)
      mstore(add(0x04, _ptr), _app_console)
      mstore(add(0x24, _ptr), _registry_exec_id)
      mstore(add(0x44, _ptr), 0x60) // data read offset
      mstore(add(0x64, _ptr), add(0x124, _normalized_desc_len))

      mstore(add(0x84, _ptr), _register_app_sel)  // registerApp()
      mstore(add(0x88, _ptr), _app_name)          // app name
      mstore(add(0xa8, _ptr), _registry_storage)  // app storage

      // setup data read offsets...
      mstore(add(0xc8, _ptr), 0x80)
      mstore(add(0xe8, _ptr), add(0xa0, _normalized_desc_len))

      // add _app_description to calldata
      mstore(add(0x108, _ptr), mload(_app_description))
      let _offset := 0x0
      for { } lt(_offset, _normalized_desc_len) { _offset := add(0x20, _offset) } {
        mstore(add(0x128, add(_offset, _ptr)), mload(add(0x20, add(_offset, _app_description))))
      }

      // add _ctx to calldata
      mstore(add(0x128, add(_offset, _ptr)), 0x60)
      mstore(add(0x20, add(0x128, add(_offset, _ptr))), mload(add(0x20, _ctx)))
      mstore(add(0x40, add(0x128, add(_offset, _ptr))), mload(add(0x40, _ctx)))
      mstore(add(0x60, add(0x128, add(_offset, _ptr))), mload(add(0x60, _ctx)))

      let _ret := call(gas, _registry_storage, 0, _ptr, _ptr_length, 0x0, 0x0)
      if iszero(_ret) { revert (0, 0) }
    }
  }

  function registerVersion(bytes32 _app_name, bytes32 _version_name, address _version_storage, bytes memory _version_description) public onlyAdmin() {
    require(_app_name != bytes32(0) && _version_name != bytes32(0) && _version_description.length != 0);
    require(default_storage != address(0) && default_registry_exec_id != bytes32(0) && default_provider != bytes32(0) && default_updater != address(0));

    address __version_storage = _version_storage;
    if (__version_storage == address(0)) {
      __version_storage = default_storage;
    }

    bytes4 _registry_exec_sel = APP_EXEC;
    bytes4 _register_version_sel = REGISTER_VERSION;

    address _registry_storage = default_storage;
    address _version_console = registries[default_registry_exec_id].version_console;
    require(_version_console != address(0));

    bytes32 _registry_exec_id = default_registry_exec_id;
    bytes memory _ctx = buildContext(default_registry_exec_id, bytes32(msg.sender), 0);

    assembly {
      let _normalized_desc_len := mload(_version_description)
      if gt(mod(_normalized_desc_len, 0x20), 0) {
        _normalized_desc_len := sub(add(_normalized_desc_len, 0x20), mod(_normalized_desc_len, 0x20))
      }

      let _ptr_length := sub(add(add(0x168, _normalized_desc_len), 0x80), 0x04)
      let _ptr := mload(0x40)
      mstore(_ptr, _registry_exec_sel)
      mstore(add(0x04, _ptr), _version_console)
      mstore(add(0x24, _ptr), _registry_exec_id)
      mstore(add(0x44, _ptr), 0x60)
      mstore(add(0x64, _ptr), add(0x144, _normalized_desc_len))

      mstore(add(0x84, _ptr), _register_version_sel)
      mstore(add(0x88, _ptr), _app_name)
      mstore(add(0xa8, _ptr), _version_name)
      mstore(add(0xc8, _ptr), __version_storage)

      // setup data read offsets...
      mstore(add(0xe8, _ptr), 0xa0)
      mstore(add(0x108, _ptr), add(0xc0, _normalized_desc_len))

      // add _version_description to calldata
      mstore(add(0x128, _ptr), mload(_version_description))
      let _offset := 0x0
      for { } lt(_offset, _normalized_desc_len) { _offset := add(0x20, _offset) } {
        mstore(add(0x148, add(_offset, _ptr)), mload(add(0x20, add(_offset, _version_description))))
      }

      // add _ctx to calldata
      mstore(add(0x148, add(_normalized_desc_len, _ptr)), 0x60)
      mstore(add(0x20, add(0x148, add(_normalized_desc_len, _ptr))), mload(add(0x20, _ctx)))
      mstore(add(0x40, add(0x148, add(_normalized_desc_len, _ptr))), mload(add(0x40, _ctx)))
      mstore(add(0x60, add(0x148, add(_normalized_desc_len, _ptr))), mload(add(0x60, _ctx)))

      let _ret := call(gas, _registry_storage, 0, _ptr, _ptr_length, 0x0, 0x0)
      if iszero(_ret) { revert (0, 0) }
    }
  }

  function finalizeVersion(bytes32 _app_name, bytes32 _version_name, address _app_init, bytes4 _app_init_sel, bytes memory _app_init_desc) public onlyAdmin() {
    require(_app_name != bytes32(0) && _version_name != bytes32(0) && _app_init != address(0));
    require(default_storage != address(0) && default_registry_exec_id != bytes32(0) && default_provider != bytes32(0));

    bytes4 _registry_exec_sel = APP_EXEC;
    bytes4 _finalize_version_sel = FINALIZE_VERSION;

    address _registry_storage = default_storage;
    address _version_console = registries[default_registry_exec_id].version_console;
    require(_version_console != address(0));

    bytes32 _registry_exec_id = default_registry_exec_id;
    bytes memory _ctx = buildContext(default_registry_exec_id, bytes32(msg.sender), 0);

    assembly {
      let _normalized_desc_len := mload(_app_init_desc)
      if gt(mod(_normalized_desc_len, 0x20), 0) {
        _normalized_desc_len := sub(add(_normalized_desc_len, 0x20), mod(_normalized_desc_len, 0x20))
      }

      let _ptr_length := sub(add(add(0x168, add(0x20, _normalized_desc_len)), 0x80), 0x04)
      let _ptr := mload(0x40)
      mstore(_ptr, _registry_exec_sel)
      mstore(add(0x04, _ptr), _version_console)
      mstore(add(0x24, _ptr), _registry_exec_id)
      mstore(add(0x44, _ptr), 0x60) // data read offset
      mstore(add(0x64, _ptr), add(0x164, _normalized_desc_len))

      mstore(add(0x84, _ptr), _finalize_version_sel)  // finalizeVersion()
      mstore(add(0x88, _ptr), _app_name)              // app name
      mstore(add(0xa8, _ptr), _version_name)          // version name
      mstore(add(0xc8, _ptr), _app_init)              // app initializer

      // add _app_init_calldata to calldata
      mstore(add(0xe8, _ptr), _app_init_sel)

      // setup data read offsets...
      mstore(add(0x108, _ptr), 0xc0)
      mstore(add(0x128, _ptr), add(0xe0, _normalized_desc_len))

      // add _app_init_desc to calldata
      mstore(add(0x148, _ptr), mload(_app_init_desc))
      let _offset := 0x0
      for { } lt(_offset, _normalized_desc_len) { _offset := add(0x20, _offset) } {
        mstore(add(add(0x168, _ptr), _offset), mload(add(0x20, add(_offset, _app_init_desc))))
      }

      // add _ctx to calldata
      mstore(add(add(0x168, _ptr), _offset), 0x60)
      mstore(add(0x20, add(add(0x168, _ptr), _offset)), mload(add(0x20, _ctx)))
      mstore(add(0x40, add(add(0x168, _ptr), _offset)), mload(add(0x40, _ctx)))
      mstore(add(0x60, add(add(0x168, _ptr), _offset)), mload(add(0x60, _ctx)))

      let _ret := call(gas, _registry_storage, 0, _ptr, _ptr_length, 0x0, 0x0)
      if iszero(_ret) { revert (0, 0) }
    }
  }

  function addFunctions(bytes32 _app_name, bytes32 _version_name, bytes4[] memory _function_sigs, address[] memory _function_addrs) public onlyAdmin() {
    require(_app_name != bytes32(0) && _version_name != bytes32(0) && _function_sigs.length != 0 && _function_addrs.length != 0 && _function_sigs.length == _function_addrs.length);
    require(default_storage != address(0) && default_registry_exec_id != bytes32(0) && default_provider != bytes32(0));

    bytes4 _registry_exec_sel = APP_EXEC;
    bytes4 _add_functions_sel = ADD_FUNCTIONS;

    address _registry_storage = default_storage;
    address _impl_console = registries[default_registry_exec_id].implementation_console;
    require(_impl_console != address(0));

    bytes32 _registry_exec_id = default_registry_exec_id;
    bytes memory _ctx = buildContext(default_registry_exec_id, bytes32(msg.sender), 0);

    assembly {
      let _ptr_length := sub(add(add(add(0x148, add(0x20, mul(0x20, mload(_function_sigs)))), add(0x20, mul(0x20, mload(_function_addrs)))), 0x80), 0x04)
      let _ptr := mload(0x40)
      mstore(_ptr, _registry_exec_sel)
      mstore(add(0x04, _ptr), _impl_console)
      mstore(add(0x24, _ptr), _registry_exec_id)
      mstore(add(0x44, _ptr), 0x60) // data read offset
      mstore(add(0x64, _ptr), add(add(0x80, 0xe4), add(mul(0x20, mload(_function_sigs)), mul(0x20, mload(_function_addrs)))))

      mstore(add(0x84, _ptr), _add_functions_sel) // addFunctions()
      mstore(add(0x88, _ptr), _app_name)          // app name
      mstore(add(0xa8, _ptr), _version_name)      // version name

      // setup data read offsets...
      mstore(add(0xc8, _ptr), 0xa0)
      mstore(add(0xe8, _ptr), add(0xc0, mul(0x20, mload(_function_sigs))))
      mstore(add(0x108, _ptr), add(0xe0, add(mul(0x20, mload(_function_sigs)), mul(0x20, mload(_function_addrs)))))

      // add _function_sigs to calldata
      mstore(add(0x128, _ptr), mload(_function_sigs))
      let _offset := 0x0
      for { } lt(_offset, mul(0x20, mload(_function_sigs))) { _offset := add(0x20, _offset) } {
        mstore(add(add(0x20, 0x128), add(_offset, _ptr)), mload(add(0x20, add(_offset, _function_sigs))))
      }

      // add _function_addrs to calldata
      mstore(add(0x148, add(mul(0x20, mload(_function_sigs)), _ptr)), mload(_function_addrs))
      _offset := 0x0
      for { } lt(_offset, mul(0x20, mload(_function_addrs))) { _offset := add(0x20, _offset) } {
        mstore(add(add(0x20, add(0x148, mul(0x20, mload(_function_sigs)))), add(_offset, _ptr)), mload(add(0x20, add(_offset, _function_addrs))))
      }

      // add _ctx to calldata
      mstore(add(0x168, add(mul(0x20, mload(_function_sigs)), add(_offset, _ptr))), 0x60)
      mstore(add(0x20, add(0x168, add(mul(0x20, mload(_function_sigs)), add(_offset, _ptr)))), mload(add(0x20, _ctx)))
      mstore(add(0x40, add(0x168, add(mul(0x20, mload(_function_sigs)), add(_offset, _ptr)))), mload(add(0x40, _ctx)))
      mstore(add(0x60, add(0x168, add(mul(0x20, mload(_function_sigs)), add(_offset, _ptr)))), mload(add(0x60, _ctx)))

      let _ret := call(gas, _registry_storage, 0, _ptr, _ptr_length, 0x0, 0x0)
      if iszero(_ret) { revert (0, 0) }
    }
  }

  function buildContext(bytes32 _exec_id, bytes32 _provider, uint _val) internal pure returns (bytes memory _ctx) {
    _ctx = new bytes(96);
    assembly {
      mstore(add(0x20, _ctx), _exec_id)
      mstore(add(0x40, _ctx), _provider)
      mstore(add(0x60, _ctx), _val)
    }
  }
}

// File: tmp/AbstractStorage.sol

contract AbstractStorage {

  struct Application {
    bool is_paused;
    bool is_active;
    bool is_payable;
    address updater;
    address script_exec;
    address init;
  }

  // Keeps track of the number of applicaions initialized, so that each application has a unique execution id
  uint private nonce;

  // Maps execution ids to application information
  mapping (bytes32 => Application) public app_info;

  // Maps execution ids to permissioned storage addresses, to index in allowed_addr_list (if nonzero, can store)
  // Because uint value is 0 by default, this reference is 1-indexed (actual indices are minus 1)
  mapping (bytes32 => mapping (address => uint)) public allowed_addresses;

  // Maps execution ids to an array of allowed addresses
  mapping (bytes32 => address[]) public allowed_addr_list;

  /// CONSTANTS ///

  // ACTION REQUESTORS //

  bytes4 internal constant EMITS = bytes4(keccak256('emits:'));
  bytes4 internal constant STORES = bytes4(keccak256('stores:'));
  bytes4 internal constant PAYS = bytes4(keccak256('pays:'));
  bytes4 internal constant THROWS = bytes4(keccak256('throws:'));

  // OTHER //

  bytes internal constant DEFAULT_EXCEPTION = "DefaultException";

  /// EVENTS ///

  // GENERAL //

  event ApplicationInitialized(bytes32 indexed execution_id, address indexed init_address, address script_exec, address updater);
  event ApplicationFinalization(bytes32 indexed execution_id, address indexed init_address);
  event ApplicationExecution(bytes32 indexed execution_id, address indexed script_target);
  event DeliveredPayment(bytes32 indexed execution_id, address indexed destination, uint amount);

  // EXCEPTION HANDLING //

  event ApplicationException(address indexed application_address, bytes32 indexed execution_id, bytes message); // Target execution address has emitted an exception, and reverted state

  // Modifier - ensures an application is not paused or inactive, and that the sender matches the script exec address
  // If value was sent, ensures the application is marked as payable
  modifier validState(bytes32 _exec_id) {
    require(
      app_info[_exec_id].is_paused == false
      && app_info[_exec_id].is_active == true
      && app_info[_exec_id].script_exec == msg.sender
    );

    // If value was sent, ensure application is marked payable
    if (msg.value > 0)
      require(app_info[_exec_id].is_payable);

    _;
  }

  // Modifier - ensures an application is paused, and that the sender is the app's updater address
  modifier onlyUpdate(bytes32 _exec_id) {
    require(app_info[_exec_id].is_paused && app_info[_exec_id].updater == msg.sender);
    _;
  }

  /// APPLICATION EXECUTION ///

  /*
  ** Application execution follows a standard pattern:
  ** Application libraries are forwarded passed-in calldata via staticcall (no
  ** state changes). Application libraries must make use of 'read' and 'readMulti'
  ** to read values from storage and execute logic on read values. Because application
  ** libraries are stateless, they cannot emit events, store data, or forward Ether.
  **
  ** As such, applications must tell the storage contract which of these events should
  ** occur upon successful execution so that the storage contract is able to handle them
  ** for the application library. This is done through the data returned by the application
  ** library. Returned data is formatted in such a way that the storage contract is able to
  ** parse the data and execute various actions.
  **
  ** Actions allowed are: EMITS, PAYS, STORES, and THROWS. More information on these is provided
  ** in the executeAppReturn function.
  */

  /*
  Executes an initialized application under a given execution id, with given logic target and calldata

  @param _target: The logic address for the application to execute. Passed-in calldata is forwarded here as a static call, and the return value is parsed for executable actions.
  @param _exec_id: The application execution id under which action requests for this application are made
  @param _calldata: The calldata to forward to the application. Typically, this is created in the script exec contract and contains information about the original sender's address and execution id
  @mod validState(_exec_id): Ensures the application is active and unpaused, and that the sender is the script exec contract. Also ensures that if wei was sent, the app is registered as payable
  @return n_emitted: The number of events emitted on behalf of the application
  @return n_paid: The number of destinations ETH was forwarded to on behalf of the application
  @return n_stored: The number of storage slots written to on behalf of the application
  */
  function exec(address _target, bytes32 _exec_id, bytes _calldata) public payable validState(_exec_id) returns (uint n_emitted, uint n_paid, uint n_stored) {
    // Ensure valid input and input size - minimum 4 bytes
    require(_calldata.length >= 4 && _target != address(0) && _exec_id != bytes32(0));

    // Ensure sender is script executor for this exec id
    require(msg.sender == app_info[_exec_id].script_exec);

    // Ensure app logic address has been approved for this exec id
    require(allowed_addresses[_exec_id][_target] != 0);

    // Script executor and passed-in request are valid. Execute application and store return to this application's storage
    bool success;
    assembly {
      // Forward passed-in calldata to target contract
      success := staticcall(gas, _target, add(0x20, _calldata), mload(_calldata), 0, 0)
    }
    // If the call to the application failed, emit an ApplicationException and return failure
    if (!success) {
      handleException(_target, _exec_id);
      return(0, 0, 0);
    } else {
      (n_emitted, n_paid, n_stored) = executeAppReturn(_exec_id);
    }

    if (n_emitted == 0 && n_paid == 0 && n_stored == 0)
      revert('No state change occured');

    emit ApplicationExecution(_exec_id, _target);

    // If execution reaches this point, call should have succeeded -
    assert(success);
  }

  /// APPLICATION INITIALIZATION ///

  /*
  ** Applications are initialized by a script execution address (typically, a
  ** standard contract). The executor specifies a permissioned updater address,
  ** as well as an 'init' address and a set of 'allowed' permissioned addresses
  ** which can access app storage through exec calls made to this contract.
  ** The 'init' address acts as the constructor to the application, and will
  ** only be called once, with _init_calldata.
  **
  ** Script executor addresses, init addresses, and updater addresses cannot be
  ** permissioned storage addresses.
  */

  /*
  Initializes an application under a generated unique execution id. All storage requests for this application will use this execution context id.
  Applications are paused and inactive by default, and can be un-paused (and activated) by the script exec contract. This allows for fine-tuned control
  of allowed addresses prior to live functionality.

  @param _updater: This address can add or remove addresses from the exec id's allowed address list. The updater address can also pause app execution. Can be 0.
  @param _is_payable: Designates whether functions in these contracts should expect wei
  @param _init: This address contains logic for the application's initialize function, which sets up initial variables like a constructor
  @param _init_calldata: ABI-encoded calldata which will be forwarded to the init target address
  @param _allowed: These addresses can be called through this contract's exec function, and can access storage
  @return exec_id: The unique exec id to be used by this application
  */
  function initAppInstance(address _updater, bool _is_payable, address _init, bytes _init_calldata, address[] _allowed) public returns (bytes32 exec_id) {
    exec_id = keccak256(++nonce, address(this));

    uint size;
    // Execute application init call
    bool success;
    assembly {
      success := staticcall(gas, _init, add(0x20, _init_calldata), mload(_init_calldata), 0, 0)
      size := returndatasize
    }
    // If the call failed, emit an error message and return
    if (!success) {
      handleException(_init, exec_id);
      return bytes32(0);
    } else if (size > 0) {
      // If the call succeeded and returndatasize is nonzero, parse returned data for actions
      executeAppReturn(exec_id);
    }

    // Set application information, and set app to paused and inactive
    app_info[exec_id] = Application({
      is_paused: true,
      is_active: false,
      is_payable: _is_payable,
      updater: _updater,
      script_exec: msg.sender,
      init: _init
    });

    // Loop over given allowed addresses, and add to mapping
    for (uint i = 0; i < _allowed.length; i++) {
      // Allowed addresses cannot be script executor, _init address, or _updater address
      require(msg.sender != _allowed[i] && _init != _allowed[i] && _updater != _allowed[i]);
      // Allowed addresses cannot be added several times - skip this iteration
      if (allowed_addresses[exec_id][_allowed[i]] != 0)
        continue;
      allowed_addresses[exec_id][_allowed[i]] = i + 1;
      allowed_addr_list[exec_id].push(_allowed[i]);
    }

    // emit Event
    emit ApplicationInitialized(exec_id, _init, msg.sender, _updater);
    // Sanity check - ensure valid exec id
    assert(exec_id != bytes32(0));
  }

  /*
  Called by the an application's script exec contract: Activates an application and un-pauses it.

  @param _exec_id: The unique execution id under which the application stores data
  */
  function finalizeAppInstance(bytes32 _exec_id) public {
    require(_exec_id != 0);
    // Ensure application is registered, inactive, and paused
    require(
      app_info[_exec_id].script_exec == msg.sender
      && app_info[_exec_id].is_active == false
      && app_info[_exec_id].is_paused == true
    );

    // Emit event
    emit ApplicationFinalization(_exec_id, app_info[_exec_id].init);
    // Set application status as active and unpaused
    app_info[_exec_id].is_paused = false;
    app_info[_exec_id].is_active = true;
  }

  /*
  Initializes an application under a generated unique execution id, and finalizes it (disallows addition/removal of addresses). All storage requests for this application will use this execution context id.
  Applications are paused and inactive by default, and can be un-paused (and activated) by the script exec contract. This allows for fine-tuned control
  of allowed addresses prior to live functionality.

  @param _updater: This address can add or remove addresses from the exec id's allowed address list. The updater address can also pause app execution. Can be 0.
  @param _is_payable: Designates whether functions in these contracts should expect wei
  @param _init: This address contains logic for the application's initialize function, which sets up initial variables like a constructor
  @param _init_calldata: ABI-encoded calldata which will be forwarded to the init target address
  @param _allowed: These addresses can be called through this contract's exec function, and can access storage
  @return exec_id: The unique exec id to be used by this application
  */
  function initAndFinalize(address _updater, bool _is_payable, address _init, bytes _init_calldata, address[] _allowed) public returns (bytes32 exec_id) {
    exec_id = initAppInstance(_updater, _is_payable, _init, _init_calldata, _allowed);
    require(exec_id != bytes32(0));
    finalizeAppInstance(exec_id);
    assert(exec_id != bytes32(0));
  }

  /// APPLICATION RETURNDATA HANDLING ///

  /*
  This function parses data returned by an application and executes requested actions. Because applications
  are assumed to be stateless, they cannot emit events, store data, or forward payment. Therefore, these
  steps to execution are handled in the storage contract by this function.

  Returned data can execute several actions requested by the application through the use of an 'action requestor':
  Some actions mirror nested dynamic return types, which are manually encoded and decoded as they are not supported
  1. THROWS  - App requests storage revert with a given message
      --Format: bytes
        --Payload is simply an array of bytes that will be reverted back to the caller
  2. EMITS   - App requests that events be emitted. Can provide topics to index, as well as arbitrary length data
      --Format: Event[]
        --Event format: [uint n_topics][bytes32 topic_0]...[bytes32 topic_n][uint data.length][bytes data]
  3. STORES  - App requests that data be stored to its storage. App storage locations are hashed with the app's exec id
      --Format: bytes32[]
        --bytes32[] consists of a data location followed by a value to place at that location
        --as such, its length must be even
        --Ex: [value_0][location_0]...[value_n][location_n]
  4. PAYS    - App requests that ETH sent to the contract be forwarded to other addresses.
      --Format: bytes32[]
        --bytes32[] consists of an address to send ETH to, followed by an amount to send to that address
        --As such, its length must be even
        --Ex: [amt_0][bytes32(destination_0)]...[amt_n][bytes32(destination_n)]

  Returndata is structured as an array of bytes, beginning with an action requestor ('THROWS', 'PAYS', etc)
  followed by that action's appropriately-formatted data (see above). Up to 3 actions with formatted data can be placed
  into returndata, and each must be unique (i.e. no two 'EMITS' actions).

  If the THROWS action is requested, it must be the first event requested. The event will be parsed
  and logged, and no other actions will be executed. If the THROWS requestor is not the first action
  requested, this function will throw

  @param _exec_id: The execution id which references this application's storage
  @return n_emitted: The number of events emitted on behalf of the application
  @return n_paid: The number of destinations ETH was forwarded to on behalf of the application
  @return n_stored: The number of storage slots written to on behalf of the application
  */
  function executeAppReturn(bytes32 _exec_id) internal returns (uint n_emitted, uint n_paid, uint n_stored) {
    uint _ptr;      // Will be a pointer to the data returned by the application call
    uint ptr_bound; // Will be the maximum value of the pointer possible (end of the memory stored in the pointer)
    (ptr_bound, _ptr)= getReturnedData();
    // Ensure there are at least 32 bytes stored at the pointer
    require(ptr_bound >= _ptr + 32, 'Malformed returndata - invalid size');
    _ptr += 32;

    // Iterate over returned data and execute actions
    bytes4 action;
    while (_ptr <= ptr_bound && (action = getAction(_ptr)) != 0x0) {
      if (action == THROWS) {
        // If the action is THROWS and any other action has been executed, throw
        require(n_emitted == 0 && n_paid == 0 && n_stored == 0, 'Malformed returndata - THROWS out of position');
        // Execute THROWS request
        doThrow(_ptr);
        // doThrow should revert, so we should never reach this point
        assert(false);
      } else {
        if (action == EMITS) {
          // If the action is EMITS, and this action has already been executed, throw
          require(n_emitted == 0, 'Duplicate action: EMITS');
          // Otherwise, emit events and get amount of events emitted
          // doEmit returns the pointer incremented to the end of the data portion of the action executed
          (_ptr, n_emitted) = doEmit(_ptr, ptr_bound);
          // If 0 events were emitted, returndata is malformed: throw
          require(n_emitted != 0, 'Unfulfilled action: EMITS');
        } else if (action == STORES) {
          // If the action is STORES, and this action has already been executed, throw
          require(n_stored == 0, 'Duplicate action: STORES');
          // Otherwise, store data and get amount of slots written to
          // doStore increments the pointer to the end of the data portion of the action executed
          (_ptr, n_stored) = doStore(_ptr, ptr_bound, _exec_id);
          // If no storage was performed, returndata is malformed: throw
          require(n_stored != 0, 'Unfulfilled action: STORES');
        } else if (action == PAYS) {
          // If the action is PAYS, and this action has already been executed, throw
          require(n_paid == 0, 'Duplicate action: PAYS');
          // Otherwise, forward ETH and get amount of addresses forwarded to
          // doPay increments the pointer to the end of the data portion of the action executed
          (_ptr, n_paid) = doPay(_ptr, ptr_bound, _exec_id);
          // If no destinations recieved ETH, returndata is malformed: throw
          require(n_paid != 0, 'Unfulfilled action: PAYS');
        } else {
          // Unrecognized action requested. returndata is malformed: throw
          revert('Malformed returndata - unknown action');
        }
      }
    }
    assert(n_emitted != 0 || n_paid != 0 || n_stored != 0);
  }

  /*
  After validating that returned data is larger than 32 bytes, returns a pointer to the returned data
  in memory, as well as a pointer to the end of returndata in memory

  @return ptr_bounds: The pointer cannot be this value and be reading from returndata
  @return _returndata_ptr: A pointer to the returned data in memory
  */
  function getReturnedData() internal pure returns (uint ptr_bounds, uint _returndata_ptr) {
    assembly {
      // returndatasize must be minimum 96 bytes (offset, length, and requestor)
      if lt(returndatasize, 0x60) {
        mstore(0, 'Insufficient return size')
        revert(0, 0x20)
      }
      // Get memory location to which returndata will be copied
      _returndata_ptr := msize
      // Copy returned data to pointer location, starting with length
      returndatacopy(_returndata_ptr, 0x20, sub(returndatasize, 0x20))
      // Get maximum memory location value for returndata
      ptr_bounds := add(_returndata_ptr, sub(returndatasize, 0x20))
      // Set new free-memory pointer to point after the returndata in memory
      // Returndata is automatically 32-bytes padded
      mstore(0x40, add(0x20, ptr_bounds))
    }
  }

  /*
  Returns the value stored in memory at the pointer. Used to determine the size of fields in returned data

  @param _ptr: A pointer to some location in memory containing returndata
  @return length: The value stored at that pointer
  */
  function getLength(uint _ptr) internal pure returns (uint length) {
    assembly {
      length := mload(_ptr)
    }
  }

  // Executes the THROWS action, reverting any returned data back to the caller
  function doThrow(uint _ptr) internal pure {
    assert(getAction(_ptr) == THROWS);
    _ptr += 4;
    assembly {
      // The data following the action requestor is a bytes array with the data to be reverted to caller
      // The first 32 bytes is the size of the data -
      let size := mload(_ptr)
      revert(add(0x20, _ptr), size)
    }
  }

  /*
  Parses and executes a PAYS action copied from returndata and located at the pointer
  A PAYS action provides a set of addresses and corresponding amounts of ETH to send to those
  addresses. The sender must ensure the call has sufficient funds, or the call will fail
  PAYS actions follow a format of: [amt_0][address_0]...[amt_n][address_n]

  @param _ptr: A pointer in memory to an application's returned payment request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @param _exec_id: The execution id of the application which triggered the payment
  @return ptr: An updated pointer, pointing to the end of the PAYS action request in memory
  @return n_paid: The number of destinations paid out to from the returned PAYS request
  */
  function doPay(uint _ptr, uint _ptr_bound, bytes32 _exec_id) internal returns (uint ptr, uint n_paid) {
    // Ensure ETH was sent with the call
    require(msg.value > 0);
    assert(getAction(_ptr) == PAYS);
    _ptr += 4;
    // Get number of destinations
    uint num_destinations = getLength(_ptr);
    _ptr += 32;
    address pay_to;
    uint amt;
    // Loop over PAYS actions and process each one
    while (_ptr <= _ptr_bound && n_paid < num_destinations) {
      // Get the payment destination and amount from the pointer
      assembly {
        amt := mload(_ptr)
        pay_to := mload(add(0x20, _ptr))
      }
      // Invalid address was passed as a payment destination - throw
      if (pay_to == address(0) || pay_to == address(this))
        revert('PAYS: invalid destination');

      // Forward ETH and increment n_paid
      address(pay_to).transfer(amt);
      n_paid++;
      // Increment pointer
      _ptr += 64;
      // Emit event
      emit DeliveredPayment(_exec_id, pay_to, amt);
    }
    ptr = _ptr;
    assert(n_paid == num_destinations);
  }

  /*
  Parses and executes a STORES action copied from returndata and located at the pointer
  A STORES action provides a set of storage locations and corresponding values to store at those locations
  true storage locations within this contract are first hashed with the application's execution id to prevent
  storage overlaps between applications sharing the contract
  STORES actions follow a format of: [val_0][location_0]...[val_n][location_n]

  @param _ptr: A pointer in memory to an application's returned payment request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @param _exec_id: The execution id under which storage is located
  @return ptr: An updated pointer, pointing to the end of the STORES action request in memory
  @return n_paid: The number of storage locations written to from the returned PAYS request
  */
  function doStore(uint _ptr, uint _ptr_bound, bytes32 _exec_id) internal returns (uint ptr, uint n_stored) {
    assert(getAction(_ptr) == STORES && _exec_id != bytes32(0));
    _ptr += 4;
    // Get number of locations to which data will be stored
    uint num_locations = getLength(_ptr);
    _ptr += 32;
    bytes32 location;
    bytes32 value;
    // Loop over STORES actions and process each one
    while (_ptr <= _ptr_bound && n_stored < num_locations) {
      // Get storage location and value to store from the pointer
      assembly {
        value := mload(_ptr)
        location := mload(add(0x20, _ptr))
      }
      // Store the data to the location hashed with the exec id
      store(_exec_id, location, value);
      // Increment n_stored and pointer
      n_stored++;
      _ptr += 64;
    }
    ptr = _ptr;
    require(n_stored == num_locations);
  }

  /*
  Parses and executes an EMITS action copied from returndata and located at the pointer
  An EMITS action is a list of bytes that are able to be processed and passed into logging functions (log0, log1, etc)
  EMITS actions follow a format of: [Event_0][Event_1]...[Event_n]
    where each Event_i follows the format: [topic_0]...[topic_4][data.length]<data>
    -The topics array is a bytes32 array of maximum length 4 and minimum 0
    -The final data parameter is a simple bytes array, and is emitted as a non-indexed parameter

  @param _ptr: A pointer in memory to an application's returned payment request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @return ptr: An updated pointer, pointing to the end of the EMITS action request in memory
  @return n_paid: The number of events logged from the returned EMITS request
  */
  function doEmit(uint _ptr, uint _ptr_bound) internal returns (uint ptr, uint n_emitted) {
    assert(getAction(_ptr) == EMITS);
    _ptr += 4;
    // Converts number of events that will be emitted
    uint num_events = getLength(_ptr);
    _ptr += 32;
    bytes32[] memory topics;
    bytes memory data;
    // Loop over EMITS actions and process each one
    while (_ptr <= _ptr_bound && n_emitted < num_events) {
      // Get array of topics and additional data from the pointer
      assembly {
        topics := _ptr
        data := add(add(_ptr, 0x20), mul(0x20, mload(topics)))
      }
      // Get size of the Event's data in memory
      uint log_size = 32 + (32 * (1 + topics.length)) + data.length;
      assembly {
        switch mload(topics)                // topics.length
          case 0 {
            // Log Event.data array with no topics
            log0(
              add(0x20, data),              // data(ptr)
              mload(data)                   // data.length
            )
          }
          case 1 {
            // Log Event.data array with 1 topic
            log1(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics))      // topics[0]
            )
          }
          case 2 {
            // Log Event.data array with 2 topics
            log2(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics))      // topics[1]
            )
          }
          case 3 {
            // Log Event.data array with 3 topics
            log3(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics)),     // topics[1]
              mload(add(0x60, topics))      // topics[2]
            )
          }
          case 4 {
            // Log Event.data array with 4 topics
            log4(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics)),     // topics[1]
              mload(add(0x60, topics)),     // topics[2]
              mload(add(0x80, topics))      // topics[3]
            )
          }
          default {
            // Events must have 4 or fewer topics
            mstore(0, 'EMITS: invalid topic count')
            revert(0, 0x20)
          }
      }
      // Event emitted - increment n_emitted and pointer
      n_emitted++;
      _ptr += log_size;
    }
    ptr = _ptr;
    require(n_emitted == num_events);
  }

  // Return the bytes4 action requestor stored at the pointer, and cleans the remaining bytes
  function getAction(uint _ptr) internal pure returns (bytes4 action) {
    assembly {
      // Get the first 4 bytes stored at the pointer, and clean the rest of the bytes remaining
      action := and(mload(_ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }
  }

  /// APPLICATION UPGRADING ///

  /*
  ** Application initializers may specify an address which is allowed to update
  ** the logic addresses which may be used with the application. These addresses
  ** could be as simple as someone's personal address, or as complicated as
  ** voting contracts with safe upgrade mechanisms.
  */

  // The script exec contract can update itself
  function changeScriptExec(bytes32 _exec_id, address _new_script_exec) public {
    // Ensure that only the script exec contract can update itself
    require(app_info[_exec_id].script_exec == msg.sender);

    app_info[_exec_id].script_exec = _new_script_exec;
  }

  // The updater address may change an application's init address
  function changeInitAddr(bytes32 _exec_id, address _new_init) public onlyUpdate(_exec_id) {
    app_info[_exec_id].init = _new_init;
  }

  // Allows the designated updater address to pause an application
  function pauseAppInstance(bytes32 _exec_id) public {
    // Ensure sender is updater address, and app is active
    require(app_info[_exec_id].updater == msg.sender && app_info[_exec_id].is_active == true);

    // Set paused status
    app_info[_exec_id].is_paused = true;
  }

  // Allows the designated updater address to unpause an application
  function unpauseAppInstance(bytes32 _exec_id) public {
    // Ensure sender is updater address, and app is active
    require(app_info[_exec_id].updater == msg.sender && app_info[_exec_id].is_active == true);

    // Set unpaused status
    app_info[_exec_id].is_paused = false;
  }

  // Allows the designated updater address to update the application by removing allowed addresses
  function removeAllowed(bytes32 _exec_id, address[] _to_remove) public onlyUpdate(_exec_id) {
    // Loop over input addresses and delete their permissions for the given exec id
    for (uint i = 0; i < _to_remove.length; i++) {
      // Get the index of the address to remove
      uint remove_ind = allowed_addresses[_exec_id][_to_remove[i]];
      // If the index to remove is 0, this address does not exist in the application's allowed addresses. Skip this iteration
      if (remove_ind == 0)
        continue;

      // Otherwise, decrement remove_ind (allowed_addresses is 1-indexed)
      remove_ind--;
      // Remove address reference in allowed_addresses
      delete allowed_addresses[_exec_id][_to_remove[i]];

      // Get allowed address array length
      uint allowed_addr_length = allowed_addr_list[_exec_id].length;

      // The index to remove should never be out of bounds
      assert(remove_ind < allowed_addr_length);

      // If the allowed address list has length 1, simply delete the array reference and continue
      if (allowed_addr_length == 1) {
        delete allowed_addr_list[_exec_id];
        continue;
      }

      // If the index to remove is not the final index, grab the final element and swap
      if (remove_ind + 1 != allowed_addr_length) {
        address last_index = allowed_addr_list[_exec_id][allowed_addr_length - 1];
        allowed_addr_list[_exec_id][remove_ind] = last_index;
        // Update last_index mapping
        allowed_addresses[_exec_id][last_index] = remove_ind + 1;
      }

      // Decrease the array's length
      allowed_addr_list[_exec_id].length--;
    }
  }

  // Allows the designated updater address to update the application by adding allowed addresses
  function addAllowed(bytes32 _exec_id, address[] _to_add) public onlyUpdate(_exec_id) {
    // Loop over input addresses and add permissions for each address
    for (uint i = 0; i < _to_add.length; i++) {
      // Ensure the address to allow is not the script exec id, the updater, or the init address
      require(
        _to_add[i] != app_info[_exec_id].script_exec
        && _to_add[i] != app_info[_exec_id].init
        && _to_add[i] != msg.sender // Updater address
      );

      // Addresses cannot be added several times - skip this iteration
      if (allowed_addresses[_exec_id][_to_add[i]] != 0)
        continue;

      // Otherwise, push the new address to the allowed address list, and update its index
      allowed_addr_list[_exec_id].push(_to_add[i]);
      allowed_addresses[_exec_id][_to_add[i]] = allowed_addr_list[_exec_id].length;
    }
  }

  /*
  Handles an exception thrown by a deployed application - if the application provided a message, return the message
  If ether was sent, return the ether to the sender

  @param _application: The address which triggered the exception
  @param _execution_id: The execution id specified by the sender
  */
  function handleException(address _application, bytes32 _execution_id) internal {
    bytes memory message;
    assembly {
      // Copy returned data into the bytes array
      message := msize
      mstore(message, returndatasize)
      returndatacopy(add(0x20, message), 0, returndatasize)
      // Update free-memory pointer
      mstore(0x40, add(add(0x20, mload(message)), message))
    }
    // If no returndata exists, use a default message
    if (message.length == 0)
      message = DEFAULT_EXCEPTION;

    // Emit ApplicationException event with the message
    emit ApplicationException(_application, _execution_id, message);
    // If ether was sent, send it back with returnToSender
    if (msg.value > 0)
      address(msg.sender).transfer(msg.value);
  }

  // Stores data to a given location, with a key (exec id)
  function store(bytes32 _exec_id, bytes32 _location, bytes32 _data) internal {
    // Get true location to store data to - hash of location hashed with exec id
    _location = keccak256(keccak256(_location), _exec_id);
    assembly {
      // Store data
      sstore(_location, _data)
    }
  }

  /// GETTERS ///

  // Returns the addresses with permissioned storage access under the given execution id
  function getExecAllowed(bytes32 _exec_id) public view returns (address[] allowed) {
    allowed = allowed_addr_list[_exec_id];
  }

  // STORAGE READS //

  /*
  Returns data stored at a given location

  @param _location: The address to get data from
  @return data: The data stored at the location after hashing
  */
  function read(bytes32 _exec_id, bytes32 _location) public view returns (bytes32 data_read) {
    bytes32 location = keccak256(keccak256(_location), _exec_id);
    assembly {
      data_read := sload(location)
    }
  }

  /*
  Returns data stored in several nonconsecutive locations

  @param _locations: A dynamic array of storage locations to read from
  @return data_read: The corresponding data stored in the requested locations
  */
  function readMulti(bytes32 _exec_id, bytes32[] _locations) public view returns (bytes32[] data_read) {
    data_read = new bytes32[](_locations.length);
    assembly {
      // Get free-memory pointer for a hash location
      let hash_loc := mload(0x40)
      // Store the exec id in the second slot of the hash pointer
      mstore(add(0x20, hash_loc), _exec_id)

      // Loop over input and store in return data
      for { let offset := 0x20 } lt(offset, add(0x20, mul(0x20, mload(_locations)))) { offset := add(0x20, offset) } {
        // Get storage location from hash of location in input array
        mstore(hash_loc, keccak256(add(offset, _locations), 0x20))
        // Hash exec id and location hash to get storage location
        let storage_location := keccak256(hash_loc, 0x40)
        // Copy data from storage to return array
        mstore(add(offset, data_read), sload(storage_location))
      }
    }
  }

  // Ensure no funds are stuck in this address
  function withdraw() public {
    address(msg.sender).transfer(address(this).balance);
  }
}

// File: tmp/RegistryStorage.sol

contract RegistryStorage is AbstractStorage {

  // Function selector for the registry 'getAppLatestInfo' function. Used to get information relevant to initialiazation of a registered app
  bytes4 public constant GET_APP_INIT_INFO = bytes4(keccak256("getAppLatestInfo(address,bytes32,bytes32,bytes32)"));

  /*
  Hardcoded function - calls InitRegistry.getAppLatestInfo, and returns information

  @param _registry_exec_id: The execution id used with this registry app
  @param _app_provider: The id of the provider under which the app is registered
  @param _app_name: The name of the application to get information on
  @return bool 'is_payable': Whether the application has payable functionality
  @return address 'app_storage_addr': The storage address to be used with the application
  @return bytes32 'latest_version': The name of the latest stable version of the application
  @return address 'app_init_addr': The address containing the application's initialization function, as well as its getters
  @return address[] 'allowed': An array of addresses allowed to access app storage through the app storage address and script exec contract
  */
  function getAppInitInfo(bytes32 _registry_exec_id, bytes32 _app_provider, bytes32 _app_name) public view
  returns (bool, address, bytes32, address, address[]) {
    // Ensure valid input
    require(_registry_exec_id != bytes32(0) && _app_provider != bytes32(0) && _app_name != bytes32(0));

    // Place function selector in memory
    bytes4 app_init = GET_APP_INIT_INFO;

    // Get registry init address
    address target = app_info[_registry_exec_id].init;
    bool is_payable = app_info[_registry_exec_id].is_payable;

    assembly {
      // Get pointer for calldata
      let ptr := mload(0x40)
      // Set function selector
      mstore(ptr, app_init)
      // Place registry address (this), registry exec id, app provider id, and app name in calldata
      mstore(add(0x04, ptr), address)
      calldatacopy(add(0x24, ptr), 0x04, sub(calldatasize, 0x04)) // Copy registry exec id, provider, and app name from calldata
      // Read from storage
      let ret := staticcall(gas, target, ptr, 0x84, 0, 0)
      if iszero(ret) { revert (0, 0) }

      // Copy returned data to pointer, set is_payable, and return
      mstore(ptr, is_payable)
      returndatacopy(add(0x20, ptr), 0, 0x60)
      mstore(add(0x80, ptr), 0xa0)
      returndatacopy(add(0xa0, ptr), 0x80, sub(returndatasize, 0x80))
      return (ptr, add(0x20, returndatasize))
    }
  }
}

// File: tmp/VersionConsole.sol

library VersionConsole {

  using Pointers for *;
  using LibEvents for uint;
  using LibStorage for uint;

  /// PROVIDER STORAGE ///

  // Provider namespace - all app and version storage is seeded to a provider
  // [PROVIDERS][provider_id]
  bytes32 internal constant PROVIDERS = keccak256("registry_providers");

  /// APPLICATION STORAGE ///

  // Application namespace - all app info and version storage is mapped here
  // [PROVIDERS][provider_id][APPS][app_name]
  bytes32 internal constant APPS = keccak256("apps");

  // Application version list location - (bytes32 array)
  // [PROVIDERS][provider_id][APPS][app_name][APP_VERSIONS_LIST] = bytes32[] version_names
  bytes32 internal constant APP_VERSIONS_LIST = keccak256("app_versions_list");

  // Application storage address location - address
  // [PROVIDERS][provider_id][APPS][app_name][APP_STORAGE_IMPL] = address app_default_storage_addr
  bytes32 internal constant APP_STORAGE_IMPL = keccak256("app_storage_impl");

  /// VERSION STORAGE ///

  // Version namespace - all version and function info is mapped here
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS]
  bytes32 internal constant VERSIONS = keccak256("versions");

  // Version description location - (bytes array)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_hash][VER_DESC] = bytes description
  bytes32 internal constant VER_DESC = keccak256("ver_desc");

  // Version "is finalized" location - whether a version is ready for use (all intended functions implemented)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_IS_FINALIZED] = bool is_finalized
  bytes32 internal constant VER_IS_FINALIZED = keccak256("ver_is_finalized");

  // Version storage address - if nonzero, overrides application-specified storage address
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_PERMISSIONED] = address version_storage_addr
  bytes32 internal constant VER_STORAGE_IMPL = keccak256("ver_storage_impl");

  // Version initialization address location - contains the version's 'init' function
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_ADDR] = address ver_init_addr
  bytes32 internal constant VER_INIT_ADDR = keccak256("ver_init_addr");

  // Version initialization function signature - called when initializing an instance of a version
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_SIG] = bytes4 init_signature
  bytes32 internal constant VER_INIT_SIG = keccak256("ver_init_signature");

  // Version 'init' function description location - bytes of a version's initialization function description
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_DESC] = bytes description
  bytes32 internal constant VER_INIT_DESC = keccak256("ver_init_desc");

  /// EVENT TOPICS ///

  // event VersionRegistered(bytes32 indexed execution_id, bytes32 indexed provider_id, bytes32 indexed app_name, bytes32 version_name);
  bytes32 internal constant VERSION_REGISTERED = keccak256("VersionRegistered(bytes32,bytes32,bytes32,bytes32)");

  // event VersionReleased(bytes32 indexed execution_id, bytes32 indexed provider_id, bytes32 indexed app_name, bytes32 version_name);
  bytes32 internal constant VERSION_RELEASED = keccak256("VersionReleased(bytes32,bytes32,bytes32,bytes32)");

  /// FUNCTION SELECTORS ///

  // Function selector for storage 'readMulti'
  // readMulti(bytes32 exec_id, bytes32[] locations)
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /// FUNCTIONS ///

  /*
  Registers a version of an application under the sender's provider id

  @param _app: The name of the application under which the version will be registered
  @param _ver_name: The name of the version to register
  @param _ver_storage: The storage address to use for this version. If left empty, storage uses application default address
  @param _ver_desc: The decsription of the version
  @param _context: The execution context for this application - a 96-byte array containing (in order):
    1. Application execution id
    2. Original script sender (address, padded to 32 bytes)
    3. Wei amount sent with transaction to storage
  @return bytes: A formatted bytes array that will be parsed by storage to emit events, forward payment, and store data
  */
  function registerVersion(bytes32 _app, bytes32 _ver_name, address _ver_storage, bytes memory _ver_desc, bytes memory _context) public view
  returns (bytes memory) {
    // Ensure input is correctly formatted
    require(_context.length == 96);
    require(_app != bytes32(0) && _ver_name != bytes32(0) && _ver_desc.length > 0);

    bytes32 exec_id;
    bytes32 provider;

    // Parse context array and get execution id and provider
    (exec_id, provider, ) = parse(_context);

    // Place app storage location in calldata
    bytes32 temp = keccak256(keccak256(provider), PROVIDERS); // Use a temporary var to get app base storage location
    temp = keccak256(keccak256(_app), keccak256(APPS, temp));

    /// Ensure application is already registered, and that the version name is unique.
    /// Additionally, get the app's default storage address, and the app's version list length -

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Place exec id, data read offset, and read size to calldata
    cdPush(ptr, exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 4);
    cdPush(ptr, temp); // Push app base storage location to read buffer
    cdPush(ptr, keccak256(keccak256(_ver_name), keccak256(VERSIONS, temp))); // Push version base storage location to buffer
    cdPush(ptr, keccak256(APP_STORAGE_IMPL, temp)); // App default storage address location
    cdPush(ptr, keccak256(APP_VERSIONS_LIST, temp)); // App version list storage location
    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMulti(ptr);
    // Check returned values -
    if (
      read_values[0] == bytes32(0) // Application does not exist
      || read_values[1] != bytes32(0) // Version name already exists
    ) {
      triggerException(bytes32("InsufficientPermissions"));
    }

    // If passed in version storage address is zero, set version storage address to returned app default storage address
    if (_ver_storage == address(0))
      _ver_storage = address(read_values[2]);

    // Get app version list length
    uint num_versions = uint(read_values[3]);

    /// App is registered, and version name is unique - store version information:

    // Get pointer to free memory
    ptr = ptr.clear();

    // Set up STORES action requests -
    ptr.stores();
    // Push each storage location and value to the STORES request buffer:

    // Place incremented app version list length at app version list storage location
    ptr.store(
      num_versions + 1
    ).at(keccak256(APP_VERSIONS_LIST, temp));

    // Push new version name to end of app version list
    ptr.store(
      _ver_name
    ).at(bytes32(32 * (1 + num_versions) + uint(keccak256(APP_VERSIONS_LIST, temp))));

    // Place version name in version base storage location
    temp = keccak256(keccak256(_ver_name), keccak256(VERSIONS, temp));
    ptr.store(
      _ver_name
    ).at(temp);

    // Place version storage address in version storage address location
    ptr.store(
      _ver_storage
    ).at(keccak256(VER_STORAGE_IMPL, temp));

    // Store entirety of version description
    temp = keccak256(VER_DESC, temp);
    ptr.storeBytesAt(_ver_desc, temp);

    // Done with STORES action - set up EMITS action
    ptr.emits();

    // Add VERSION_REGISTERED topics
    ptr.topics(
      [VERSION_REGISTERED, exec_id, keccak256(provider), _app]
    );
    // Add VERSION_REGISTERED data (version name)
    // Separate line to avoid 'Stack too deep' issues
    ptr.data(_ver_name);

    // Return formatted action requests to storage
    return ptr.toBuffer();
  }

  /*
  Finalizes a registered version by providing instance initialization information

  @param _app: The name of the application under which the version is registered
  @param _ver_name: The name of the version to finalize
  @param _ver_init_address: The address which contains the version's initialization function
  @param _init_sig: The function signature for the version's initialization function
  @param _init_description: A description of the version's initialization function and parameters
  @param _context: The execution context for this application - a 96-byte array containing (in order):
    1. Application execution id
    2. Original script sender (address, padded to 32 bytes)
    3. Wei amount sent with transaction to storage
  @return bytes: A formatted bytes array that will be parsed by storage to emit events, forward payment, and store data
  */
  function finalizeVersion(bytes32 _app, bytes32 _ver_name, address _ver_init_address, bytes4 _init_sig, bytes memory _init_description, bytes memory _context) public view
  returns (bytes memory) {
    // Ensure input is correctly formatted
    require(_context.length == 96);
    require(_app != bytes32(0) && _ver_name != bytes32(0));
    require(_ver_init_address != address(0) && _init_sig != bytes4(0) && _init_description.length > 0);

    bytes32 exec_id;
    bytes32 provider;

    // Parse context array and get execution id and provider
    (exec_id, provider, ) = parse(_context);

    /// Ensure application and version are registered, and that the version is not already finalized -

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Place exec id, data read offset, and read size in buffer
    cdPush(ptr, exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 3);
    // Push app base storage, version base storage, and version finalization status storage locations to buffer
    // Get app base storage -
    bytes32 temp = keccak256(keccak256(provider), PROVIDERS);
    temp = keccak256(keccak256(_app), keccak256(APPS, temp));
    cdPush(ptr, temp);
    // Get version base storage -
    temp = keccak256(keccak256(_ver_name), keccak256(VERSIONS, temp));
    cdPush(ptr, temp);
    cdPush(ptr, keccak256(VER_IS_FINALIZED, temp));
    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMulti(ptr);
    // Check returned values -
    if (
      read_values[0] == bytes32(0) // Application does not exist
      || read_values[1] == bytes32(0) // Version does not exist
      || read_values[2] != bytes32(0) // Version already finalized
    ) {
      triggerException(bytes32("InsufficientPermissions"));
    }

    /// App and version are registered, and version is ready to be finalized -

    // Get pointer to free memory
    ptr = ptr.clear();

    // Set up STORES action requests -
    ptr.stores();
    // Push each storage location and value to the STORES request buffer:

    // Store version finalization status
    ptr.store(
      true
    ).at(keccak256(VER_IS_FINALIZED, temp));

    // Store version initialization address
    ptr.store(
      _ver_init_address
    ).at(keccak256(VER_INIT_ADDR, temp));

    // Store version initialization function selector
    ptr.store(
      _init_sig
    ).at(keccak256(VER_INIT_SIG, temp));

    // Store entirety of version initialization function description
    ptr.storeBytesAt(_init_description, keccak256(VER_INIT_DESC, temp));

    // Done with STORES action - set up EMITS action
    ptr.emits();

    // Add VERSION_RELEASED topics
    ptr.topics(
      [VERSION_RELEASED, exec_id, keccak256(provider), _app]
    );
    // Add VERSION_RELEASED data (version name)
    // Separate line to avoid 'Stack too deep' issues
    ptr.data(_ver_name);

    // Return formatted action requests to storage
    return ptr.toBuffer();
  }

  /*
  Creates a calldata buffer in memory with the given function selector

  @param _selector: The function selector to push to the first location in the buffer
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function cdBuff(bytes4 _selector) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Place initial length (4 bytes) in buffer
      mstore(ptr, 0x04)
      // Place function selector in buffer, after length
      mstore(add(0x20, ptr), _selector)
      // Update free-memory pointer - it's important to note that this is not actually free memory, if the pointer is meant to expand
      mstore(0x40, add(0x40, ptr))
    }
  }

  /*
  Pushes a value to the end of a calldata buffer, and updates the length

  @param _ptr: A pointer to the start of the buffer
  @param _val: The value to push to the buffer
  */
  function cdPush(uint _ptr, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to end of buffer (overwrites memory - be careful!)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x2c, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @return read_values: The values read from storage
  */
  function readMulti(uint _ptr) internal view returns (bytes32[] memory read_values) {
    bool success;
    assembly {
      // Minimum length for 'readMulti' - 1 location is 0x84
      if lt(mload(_ptr), 0x84) { revert (0, 0) }
      // Read from storage
      success := staticcall(gas, caller, add(0x20, _ptr), mload(_ptr), 0, 0)
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Reverts state changes, but passes message back to caller

  @param _message: The message to return to the caller
  */
  function triggerException(bytes32 _message) internal pure {
    assembly {
      mstore(0, _message)
      revert(0, 0x20)
    }
  }


  // Parses context array and returns execution id, provider, and sent wei amount
  function parse(bytes memory _context) internal pure returns (bytes32 exec_id, bytes32 provider, uint wei_sent) {
    assembly {
      exec_id := mload(add(0x20, _context))
      provider := mload(add(0x40, _context))
      wei_sent := mload(add(0x60, _context))
    }
    // Ensure exec id and provider are valid
    if (provider == bytes32(0) || exec_id == bytes32(0))
      triggerException(bytes32("UnknownContext"));
  }
}

// File: tmp/ArrayUtils.sol

library ArrayUtils {

  function toUintArr(bytes32[] memory arr) internal pure returns (uint[] memory converted) {
    assembly {
      converted := arr
    }
  }

  function toIntArr(bytes32[] memory arr) internal pure returns (int[] memory converted) {
    assembly {
      converted := arr
    }
  }

  function toAddressArr(bytes32[] memory arr) internal pure returns (address[] memory converted) {
    assembly {
      converted := arr
    }
  }
}

// File: tmp/InitRegistry.sol

library InitRegistry {

  /// PROVIDER STORAGE ///

  // Provider namespace - all app and version storage is seeded to a provider
  // [PROVIDERS][provider_id]
  bytes32 internal constant PROVIDERS = keccak256("registry_providers");

  // Storage location for a list of all applications released by this provider
  // [PROVIDERS][provider_id][PROVIDER_APP_LIST] = bytes32[] registered_apps
  bytes32 internal constant PROVIDER_APP_LIST = keccak256("provider_app_list");

  /// APPLICATION STORAGE ///

  // Application namespace - all app info and version storage is mapped here
  // [PROVIDERS][provider_id][APPS][app_name]
  bytes32 internal constant APPS = keccak256("apps");

  // Application description location - (bytes array)
  // [PROVIDERS][provider_id][APPS][app_name][APP_DESC] = bytes description
  bytes32 internal constant APP_DESC = keccak256("app_desc");

  // Application version list location - (bytes32 array)
  // [PROVIDERS][provider_id][APPS][app_name][APP_VERSIONS_LIST] = bytes32[] version_names
  bytes32 internal constant APP_VERSIONS_LIST = keccak256("app_versions_list");

  // Application storage address location - address
  // [PROVIDERS][provider_id][APPS][app_name][APP_STORAGE_IMPL] = address app_default_storage_addr
  bytes32 internal constant APP_STORAGE_IMPL = keccak256("app_storage_impl");

  /// VERSION STORAGE ///

  // Version namespace - all version and function info is mapped here
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS]
  bytes32 internal constant VERSIONS = keccak256("versions");

  // Version description location - (bytes array)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_hash][VER_DESC] = bytes description
  bytes32 internal constant VER_DESC = keccak256("ver_desc");

  // Version "is finalized" location - whether a version is ready for use (all intended functions implemented)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_IS_FINALIZED] = bool is_finalized
  bytes32 internal constant VER_IS_FINALIZED = keccak256("ver_is_finalized");

  // Version function list location - (bytes4 array)
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_FUNCTION_LIST] = bytes4[] function_signatures
  bytes32 internal constant VER_FUNCTION_LIST = keccak256("ver_functions_list");

  // Version function address location - stores the address where each corresponding version's function is located
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_FUNCTION_ADDRESSES] = address[] function_addresses
  bytes32 internal constant VER_FUNCTION_ADDRESSES = keccak256("ver_function_addrs");

  // Version storage address - if nonzero, overrides application-specified storage address
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_PERMISSIONED] = address version_storage_addr
  bytes32 internal constant VER_STORAGE_IMPL = keccak256("ver_storage_impl");

  // Version initialization address location - contains the version's 'init' function
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_ADDR] = address ver_init_addr
  bytes32 internal constant VER_INIT_ADDR = keccak256("ver_init_addr");

  // Version initialization function signature - called when initializing an instance of a version
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_SIG] = bytes4 init_signature
  bytes32 internal constant VER_INIT_SIG = keccak256("ver_init_signature");

  // Version 'init' function description location - bytes of a version's initialization function description
  // [PROVIDERS][provider_id][APPS][app_hash][VERSIONS][ver_name][VER_INIT_DESC] = bytes description
  bytes32 internal constant VER_INIT_DESC = keccak256("ver_init_desc");

  /// FUNCTION SELECTORS ///

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  /// SCRIPT REGISTRY INIT ///

  // Empty init function for simple script registry
  function init() public pure { }

  /// PROVIDER INFORMATION ///

  /*
  Returns a list of all applications registered by the provider

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider's id
  @return registered_apps: A list of the names of all applications registered by this provider
  */
  function getProviderInfo(address _storage, bytes32 _exec_id, bytes32 _provider) public view
  returns (bytes32[] memory registered_apps) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0) && _provider != bytes32(0));

    // Create 'read' calldata buffer in memory
    uint ptr = cdBuff(RD_SING);
    // Push exec id to calldata buffer
    cdPush(ptr, _exec_id);
    // Place provider app list storage location in calldata buffer
    cdPush(ptr, keccak256(PROVIDER_APP_LIST, keccak256(_provider, PROVIDERS)));
    // Read single value from storage, and place return in buffer
    uint app_count = uint(readSingleFrom(ptr, _storage));

    // If the provider has not registered any applications, return an empty array
    if (app_count == 0)
      return registered_apps;

    // Overwrite previous read buffer with readMulti buffer
    cdOverwrite(ptr, RD_MULTI);
    // Place exec id, data read offset, and read size in calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(app_count));
    // Get base storage location for provider app list
    uint provider_list_storage = uint(keccak256(PROVIDER_APP_LIST, keccak256(_provider, PROVIDERS)));
    // Loop over app coutn and store list index locations in calldata buffer
    for (uint i = 1; i <= app_count; i++)
      cdPush(ptr, bytes32((32 * i) + provider_list_storage));

    // Read from storage and store return in buffer
    registered_apps = readMultiFrom(ptr, _storage);
  }

  /*
  Returns a list of all applications registered by the provider

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider
  @return provider: The hash id associated with this provider
  @return registered_apps: A list of the names of all applications registered by this provider
  */
  function getProviderInfoFromAddress(address _storage, bytes32 _exec_id, address _provider) public view
  returns (bytes32 provider, bytes32[] memory registered_apps) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0) && bytes32(_provider) != bytes32(0));
    // Get provider id from provider address
    provider = keccak256(bytes32(_provider));

    // Create 'read' calldata buffer in memory
    uint ptr = cdBuff(RD_SING);
    // Push exec id to calldata buffer
    cdPush(ptr, _exec_id);
    // Place provider app list storage location in calldata buffer
    cdPush(ptr, keccak256(PROVIDER_APP_LIST, keccak256(provider, PROVIDERS)));
    // Read single value from storage, and place return in buffer
    uint app_count = uint(readSingleFrom(ptr, _storage));

    // If the provider has not registered any applications, return an empty array
    if (app_count == 0)
      return (provider, registered_apps);

    // Overwrite previous read buffer with readMulti buffer
    cdOverwrite(ptr, RD_MULTI);
    // Place exec id, data read offset, and read size in calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(app_count));
    // Get base storage location for provider app list
    uint provider_list_storage = uint(keccak256(PROVIDER_APP_LIST, keccak256(provider, PROVIDERS)));
    // Loop over app coutn and store list index locations in calldata buffer
    for (uint i = 1; i <= app_count; i++)
      cdPush(ptr, bytes32((32 * i) + provider_list_storage));

    // Read from storage and store return in buffer
    registered_apps = readMultiFrom(ptr, _storage);
  }

  /// APPLICATION INFORMATION ///

  /*
  Returns basic information on an application

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @return num_versions: The number of versions of an application
  @return app_default_storage: The default storage location for an application. All versions use this storage location, unless they specify otherwise
  @return app_description: The bytes of an application's description
  */
  function getAppInfo(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app) public view
  returns (uint num_versions, address app_default_storage, bytes memory app_description) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0));

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Place exec id, data read offset, and read size to calldata
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 3);
    // Push app version list count, app default storage, and app description size storage locations to calldata buffer
    // Get app base storage -
    bytes32 temp = keccak256(_provider, PROVIDERS);
    temp = keccak256(keccak256(_app), keccak256(APPS, temp));
    cdPush(ptr, keccak256(APP_VERSIONS_LIST, temp)); // App version list location
    cdPush(ptr, keccak256(APP_STORAGE_IMPL, temp)); // App default storage address location
    cdPush(ptr, keccak256(APP_DESC, temp)); // App description size location

    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMultiFrom(ptr, _storage);

    // Get returned values
    num_versions = uint(read_values[0]);
    app_default_storage = address(read_values[1]);
    uint desc_size = uint(read_values[2]);

    // Normalize description size to 32-byte chunks for next readMulti
    uint desc_size_norm = desc_size / 32;
    if (desc_size % 32 != 0)
      desc_size_norm++;

    // Overwrite previous buffer to create a new readMulti buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and normalized read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(desc_size_norm));
    // Get app description base storage location
    temp = keccak256(APP_DESC, temp);
    // Loop over description size and add storage locations to buffer
    for (uint i = 1; i <= desc_size_norm; i++)
      cdPush(ptr, bytes32((32 * i) + uint(temp)));

    // Read from storage, and store return in buffer
    app_description = readMultiBytesFrom(ptr, desc_size, _storage);
  }

  /*
  Returns a list of all versions registered in an application

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @return version_list: A list of all version names associated with this application, in order from oldest to latest
  */
  function getAppVersions(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app) public view
  returns (uint app_version_count, bytes32[] memory version_list) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0));

    // Create 'read' calldata buffer in memory
    uint ptr = cdBuff(RD_SING);
    // Push exec id and app version list count location to buffer
    cdPush(ptr, _exec_id);
    // Get app base storage location
    bytes32 temp = keccak256(_provider, PROVIDERS);
    temp = keccak256(APPS, temp);
    temp = keccak256(keccak256(_app), temp);
    cdPush(ptr, keccak256(APP_VERSIONS_LIST, temp));
    // Read from storage and place return in buffer
    app_version_count = uint(readSingleFrom(ptr, _storage));

    // If an application has no registered versions, return an empty array
    if (app_version_count == 0)
      return (app_version_count, version_list);

    // Overwrite previous buffer with readMulti calldata buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and read size to calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(app_version_count));
    // Get app version list base storage location
    temp = keccak256(APP_VERSIONS_LIST, temp);
    // Loop over version count and store each list index location in calldata buffer
    for (uint i = 1; i <= app_version_count; i++)
      cdPush(ptr, bytes32((i * 32) + uint(temp)));

    // Read from storage and store return in buffer
    version_list = readMultiFrom(ptr, _storage);
  }

  struct AppInfoHelper {
    bytes32 temp;
    uint list_length;
  }

  /*
  Returns initialization and allowed addresses for the latest finalized version of an application

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @return app_storage_addr: The address where instance storage will be located
  @return latest_version: The name of the latest version of the application
  @return app_init_addr: The address which contains the application's init function
  @return allowed: An array of addresses whcih implement the application's functions
  */
  function getAppLatestInfo(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app) public view
  returns (address app_storage_addr, bytes32 latest_version, address app_init_addr, address[] memory allowed) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0));

    // Create struct in memory to hold values
    AppInfoHelper memory app_helper = AppInfoHelper({
      temp: keccak256(_provider, PROVIDERS),
      list_length: 0
    });

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Push exec id, data read offset, and read size to calldata
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 2);
    // Get app base storage location
    app_helper.temp = keccak256(_provider, PROVIDERS);
    app_helper.temp = keccak256(APPS, app_helper.temp);
    app_helper.temp = keccak256(keccak256(_app), app_helper.temp);
    // Push app default storage address location and app version list locations to buffer
    cdPush(ptr, keccak256(APP_STORAGE_IMPL, app_helper.temp));
    cdPush(ptr, keccak256(APP_VERSIONS_LIST, app_helper.temp));
    // Read froms storage and store return in buffer
    bytes32[] memory read_values = readMultiFrom(ptr, _storage);

    // Read returned values -
    app_storage_addr = address(read_values[0]);
    app_helper.list_length = uint(read_values[1]);
    // If list length is zero, no versions have been registered - return
    if (app_helper.list_length == 0)
      return;

    // Get app version list location
    bytes32 app_list_storage_loc = keccak256(APP_VERSIONS_LIST, app_helper.temp);
    // Get version storage seed
    app_helper.temp = keccak256(VERSIONS, app_helper.temp);
    // Loop backwards through app version list, and find the last 'finalized' version
    for (uint i = app_helper.list_length; i > 0; i--) {
      // Overwrite last buffer with a 'read' buffer
      cdOverwrite(ptr, RD_SING);
      // Push exec id and read location (app_versions_list[length - i])
      cdPush(ptr, _exec_id);
      cdPush(ptr, bytes32(uint(app_list_storage_loc) + (32 * i)));
      // Read from storage, and store return in buffer
      latest_version = readSingleFrom(ptr, _storage);

      // Hash returned version name and version storage seed
      bytes32 latest_ver_storage = keccak256(keccak256(latest_version), app_helper.temp);

      // Construct 'readMulti' calldata by overwriting previous 'read' calldata buffer
      cdOverwrite(ptr, RD_MULTI);
      // Push exec id, data read offset, and read size to buffer
      cdPush(ptr, _exec_id);
      cdPush(ptr, 0x40);
      cdPush(ptr, 4);
      // Push version status storage location to buffer
      cdPush(ptr, keccak256(VER_IS_FINALIZED, latest_ver_storage));
      // Push version init address storage location to buffer
      cdPush(ptr, keccak256(VER_INIT_ADDR, latest_ver_storage));
      // Push version address list location to buffer
      cdPush(ptr, keccak256(VER_FUNCTION_ADDRESSES, latest_ver_storage));
      // Push version storage address location to buffer
      cdPush(ptr, keccak256(VER_STORAGE_IMPL, latest_ver_storage));
      // Read from storage, and store return in buffer
      read_values = readMultiFrom(ptr, _storage);

      // Check version 'is finalized' status - if true, this is the latest version
      if (read_values[0] != bytes32(0)) {
        // Get initialization address for this version
        app_init_addr = address(read_values[1]);
        // Get version address list length
        app_helper.list_length = uint(read_values[2]);
        // Get storage address for this version
        app_storage_addr = address(read_values[3]);
        // Exit loop
        break;
      }
    }
    // If app_init_addr is still 0, no version was found - return
    if (app_init_addr == address(0)) {
      latest_version = bytes32(0);
      app_storage_addr = address(0);
      return;
    }

    /// Otherwise - get version allowed addresses

    // If the version has no allowed addresses, return
    if (app_helper.list_length == 0)
      return;

    // Overwrite previous buffers with 'readMulti' buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(app_helper.list_length));
    // Get version addresses list base location
    app_helper.temp = keccak256(keccak256(latest_version), app_helper.temp);
    app_helper.temp = keccak256(VER_FUNCTION_ADDRESSES, app_helper.temp);
    // Loop over list length and place each index storage location in buffer
    for (i = 1; i <= app_helper.list_length; i++)
      cdPush(ptr, bytes32((32 * i) + uint(app_helper.temp)));

    // Read from storage, and store return in buffer
    allowed = readMultiAddressFrom(ptr, _storage);
  }

  /// VERSION INFORMATION ///

  /*
  ** Applications are versioned. Each version may use its own storage address,
  ** overriding the designated application storage address. Versions may implement
  ** the same, or entirely different functions compared to other versions of the
  ** same application.
  **
  ** A provider may implement and alter a version as much as they want - but
  ** finalizing a version locks implementation details in stone. Versions have
  ** lists of functions they implement, along with the addresses which implement
  ** these functions, and descriptions of the implemented function.
  **
  ** An version instance is initialized through the version's 'init' function,
  ** which acts much like a constructor - but for a specific execution id.
  */

  struct StackVarHelper {
    bytes32 temp;
    uint desc_size;
    uint desc_size_norm;
  }

  /*
  Returns basic information on a version of an application

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @param _version: The name of the version registered
  @return is_finalized: Whether the provider has designated that this version is stable and ready for deployment and use
  @return num_functions: The number of functions this version implements
  @return version_storage: The storage address used by this version. Can be the same as, or different than the application's default storage address
  @return version_description: The bytes of a version's description
  */
  function getVersionInfo(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app, bytes32 _version) public view
  returns (bool is_finalized, uint num_functions, address version_storage, bytes memory version_description) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0) && _version != bytes32(0));

    // Create struct in memory to hold values
    StackVarHelper memory v_helper = StackVarHelper({
      temp: keccak256(_provider, PROVIDERS),
      desc_size: 1,
      desc_size_norm: 1
    });
    // Get version base storage location
    v_helper.temp = keccak256(APPS, v_helper.temp);
    v_helper.temp = keccak256(keccak256(_app), v_helper.temp);
    v_helper.temp = keccak256(VERSIONS, v_helper.temp);
    v_helper.temp = keccak256(keccak256(_version), v_helper.temp);

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Push exec id, data read offset, and read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 4);
    // Push version status, function count, storage address, and description array size storage locations to calldata buffer
    cdPush(ptr, keccak256(VER_IS_FINALIZED, v_helper.temp));
    cdPush(ptr, keccak256(VER_FUNCTION_LIST, v_helper.temp));
    cdPush(ptr, keccak256(VER_STORAGE_IMPL, v_helper.temp));
    cdPush(ptr, keccak256(VER_DESC, v_helper.temp));
    // Read from storage and store return in buffer
    bytes32[] memory read_values = readMultiFrom(ptr, _storage);

    // Read returned values -
    is_finalized = (read_values[0] != bytes32(0));
    num_functions = uint(read_values[1]);
    version_storage = address(read_values[2]);
    v_helper.desc_size = uint(read_values[3]);

    // Normalize description size to 32-byte chunks for next readMulti
    v_helper.desc_size_norm = v_helper.desc_size / 32;
    if (v_helper.desc_size % 32 != 0)
      v_helper.desc_size_norm++;

    // Create new readMulti calldata buffer, overwriting the previous buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(v_helper.desc_size_norm));
    // Get version description base storage location
    v_helper.temp = keccak256(VER_DESC, v_helper.temp);
    // Loop over description size and add storage locations to readMulti buffer
    for (uint i = 1; i <= v_helper.desc_size_norm; i++)
      cdPush(ptr, bytes32((32 * i) + uint(v_helper.temp)));

    // Read from storage, and store return in buffer
    version_description = readMultiBytesFrom(ptr, v_helper.desc_size, _storage);
  }

  /*
  Returns information on an version's initialization address and function. The initialization address and function are
  treated like a version's constructor.

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @param _version: The name of the version registered
  @return init_impl: The address where the version's init function is located
  @return init_signature: The 4-byte function selector used for the app's init function
  @return init_description: The bytes of the version's initialization description
  */
  function getVersionInitInfo(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app, bytes32 _version) public view
  returns (address init_impl, bytes4 init_signature, bytes memory init_description) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0) && _version != bytes32(0));

    // Create struct in memory to hold values
    StackVarHelper memory v_helper = StackVarHelper({
      temp: keccak256(_provider, PROVIDERS),
      desc_size: 1,
      desc_size_norm: 1
    });
    // Get version base storage location
    v_helper.temp = keccak256(_provider, PROVIDERS);
    v_helper.temp = keccak256(APPS, v_helper.temp);
    v_helper.temp = keccak256(keccak256(_app), v_helper.temp);
    v_helper.temp = keccak256(VERSIONS, v_helper.temp);
    v_helper.temp = keccak256(keccak256(_version), v_helper.temp);
    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Push exec id, data read offset, and read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 3);
    // Push init implementing address, init function signature, and init description size storage locations to calldata buffer
    cdPush(ptr, keccak256(VER_INIT_ADDR, v_helper.temp));
    cdPush(ptr, keccak256(VER_INIT_SIG, v_helper.temp));
    cdPush(ptr, keccak256(VER_INIT_DESC, v_helper.temp));
    // Read from storage, and store return in buffer
    bytes32[] memory read_values = readMultiFrom(ptr, _storage);

    // Get returned values -
    init_impl = address(read_values[0]);
    init_signature = bytes4(read_values[1]);
    v_helper.desc_size = uint(read_values[2]);

    // Normalize description size to 32-byte chunks for next readMulti
    v_helper.desc_size_norm = v_helper.desc_size / 32;
    if (v_helper.desc_size % 32 != 0)
      v_helper.desc_size_norm++;

    if (v_helper.desc_size_norm == 0)
      return;

    // Create new readMulti calldata buffer, overwriting the previous buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and read size to buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(v_helper.desc_size_norm));
    // Get version init description base storage location
    v_helper.temp = keccak256(VER_INIT_DESC, v_helper.temp);
    // Loop over description size and add storage locations to readMulti buffer
    for (uint i = 1; i <= v_helper.desc_size_norm; i++)
      cdPush(ptr, bytes32((32 * i) + uint(v_helper.temp)));

    // Read from storage, and store return in buffer
    init_description = readMultiBytesFrom(ptr, v_helper.desc_size, _storage);
  }

  /*
  Returns information on an version's implementation details: all implemented functions, and their addresses
  Descriptions for each function can be found by calling 'getImplementationInfo'

  @param _storage: The address where the registry's storage is located
  @param _exec_id: The execution id associated with the registry
  @param _provider: The provider id under which the application was registered
  @param _app: The name of the application registered
  @param _version: The name of the version registered
  @return function_signatures: A list of all the function selectors implemented in this version
  @return function_locations: The addresses where each corresponding function is implemented
  */
  function getVersionImplementation(address _storage, bytes32 _exec_id, bytes32 _provider, bytes32 _app, bytes32 _version) public view
  returns (bytes4[] memory function_signatures, address[] memory function_locations) {
    // Ensure valid input
    require(_storage != address(0) && _exec_id != bytes32(0));
    require(_provider != bytes32(0) && _app != bytes32(0) && _version != bytes32(0));

    // Get version base storage location
    bytes32 temp = keccak256(_provider, PROVIDERS);
    temp = keccak256(APPS, temp);
    temp = keccak256(keccak256(_app), temp);
    temp = keccak256(VERSIONS, temp);
    temp = keccak256(keccak256(_version), temp);

    // Create 'readMulti' calldata buffer in memory
    uint ptr = cdBuff(RD_MULTI);
    // Push exec id, data read offset, and read size to calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, 2);
    // Push version signature and address list storage locations to calldata
    cdPush(ptr, keccak256(VER_FUNCTION_LIST, temp));
    cdPush(ptr, keccak256(VER_FUNCTION_ADDRESSES, temp));
    // Read from storage, and store return in buffer
    bytes32[] memory read_values = readMultiFrom(ptr, _storage);

    // Get return lengths - should always be equal
    uint list_length = uint(read_values[0]);
    assert(list_length == uint(read_values[1]));

    // If the version has not implemented functions, return
    if (list_length == 0)
      return;

    // Create new 'readMulti' calldata buffer, overwriting the previous buffer
    cdOverwrite(ptr, RD_MULTI);
    // Push exec id, data read offset, and read size to calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(list_length));
    // Get function
    // Loop over read size and place function signature list index storage locations in calldata buffer
    for (uint i = 1; i <= list_length; i++) {
      cdPush(ptr, bytes32((i * 32) + uint(keccak256(VER_FUNCTION_LIST, temp))));
    }
    // Read from storage, and store return in buffer
    function_signatures = readMultiBytes4From(ptr, _storage);

    // Create new 'readMulti' calldata buffer in free memory
    ptr = cdBuff(RD_MULTI);
    // Push exec id, data read offset, and read size to calldata buffer
    cdPush(ptr, _exec_id);
    cdPush(ptr, 0x40);
    cdPush(ptr, bytes32(list_length));
    // Get function
    // Loop over read size and place function signature list index storage locations in calldata buffer
    for (i = 1; i <= list_length; i++)
      cdPush(ptr, bytes32((i * 32) + uint(keccak256(VER_FUNCTION_ADDRESSES, temp))));

    // Read from storage, and store return in buffer
    function_locations = readMultiAddressFrom(ptr, _storage);
  }

  /*
  Creates a calldata buffer in memory with the given function selector

  @param _selector: The function selector to push to the first location in the buffer
  @return ptr: The location in memory where the length of the buffer is stored - elements stored consecutively after this location
  */
  function cdBuff(bytes4 _selector) internal pure returns (uint ptr) {
    assembly {
      // Get buffer location - free memory
      ptr := mload(0x40)
      // Place initial length (4 bytes) in buffer
      mstore(ptr, 0x04)
      // Place function selector in buffer, after length
      mstore(add(0x20, ptr), _selector)
      // Update free-memory pointer - it's important to note that this is not actually free memory, if the pointer is meant to expand
      mstore(0x40, add(0x40, ptr))
    }
  }

  /*
  Creates a new calldata buffer at the pointer with the given selector. Does not update free memory

  @param _ptr: A pointer to the buffer to overwrite - will be the pointer to the new buffer as well
  @param _selector: The function selector to place in the buffer
  */
  function cdOverwrite(uint _ptr, bytes4 _selector) internal pure {
    assembly {
      // Store initial length of buffer - 4 bytes
      mstore(_ptr, 0x04)
      // Store function selector after length
      mstore(add(0x20, _ptr), _selector)
    }
  }

  /*
  Pushes a value to the end of a calldata buffer, and updates the length

  @param _ptr: A pointer to the start of the buffer
  @param _val: The value to push to the buffer
  */
  function cdPush(uint _ptr, bytes32 _val) internal pure {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push value to end of buffer (overwrites memory - be careful!)
      mstore(add(_ptr, len), _val)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x20, _ptr), len)) {
        mstore(0x40, add(add(0x2c, _ptr), len)) // Ensure free memory pointer points to the beginning of a memory slot
      }
    }
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The address to read from
  @return read_values: The values read from storage
  */
  function readMultiFrom(uint _ptr, address _storage) internal view returns (bytes32[] memory read_values) {
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The address to read from
  @return read_values: The values read from storage
  */
  function readMultiBytes4From(uint _ptr, address _storage) internal view returns (bytes4[] memory read_values) {
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
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
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Executes a 'readMulti' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _arr_len: The actual length of the bytes array being returned
  @param _storage: The address to read from
  @return read_values: The bytes array read from storage
  */
  function readMultiBytesFrom(uint _ptr, uint _arr_len, address _storage) internal view returns (bytes memory read_values) {
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
        // Copy input length to read_values - corrects length
        mstore(read_values, _arr_len)
      }
    }
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Executes a 'read' function call, given a pointer to a calldata buffer

  @param _ptr: A pointer to the location in memory where the calldata for the call is stored
  @param _storage: The address to read from
  @return read_value: The value read from storage
  */
  function readSingleFrom(uint _ptr, address _storage) internal view returns (bytes32 read_value) {
    bool success;
    assembly {
      // Length for 'read' buffer must be 0x44
      if iszero(eq(mload(_ptr), 0x44)) { revert (0, 0) }
      // Read from storage, and store return to pointer
      success := staticcall(gas, _storage, add(0x20, _ptr), mload(_ptr), _ptr, 0x20)
      // If call succeeded, store return at pointer
      if gt(success, 0) { read_value := mload(_ptr) }
    }
    if (!success)
      triggerException(bytes32("StorageReadFailed"));
  }

  /*
  Reverts state changes, but passes message back to caller

  @param _message: The message to return to the caller
  */
  function triggerException(bytes32 _message) internal pure {
    assembly {
      mstore(0, _message)
      revert(0, 0x20)
    }
  }
}

// File: tmp/LibPayments.sol

library LibPayments {

  // ACTION REQUESTORS //

  bytes4 internal constant PAYS = bytes4(keccak256('pays:'));

  // Set up a PAYS action request buffer
  function pays(uint _ptr) internal pure {
    bytes4 action_req = PAYS;
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push requestor to the of buffer
      mstore(add(_ptr, len), action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the PAYS action
      mstore(add(_ptr, add(0x04, len)), 0)
      // Increment buffer length
      mstore(_ptr, add(0x04, len))
      // Set a pointer to PAYS action length in the free slot before _ptr
      mstore(sub(_ptr, 0x20), add(_ptr, add(0x04, len)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x44, _ptr), len)) {
        mstore(0x40, add(add(0x44, _ptr), len))
      }
    }
  }

  function pay(uint _ptr, uint _amt) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push amount to the end of the buffer
      mstore(add(_ptr, len), _amt)
      // Increment buffer length
      mstore(_ptr, len)
      // Increment PAYS action length (pointer to length stored before _ptr)
      let _len_ptr := mload(sub(_ptr, 0x20))
      mstore(_len_ptr, add(1, mload(_len_ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len))
      }
    }
    return _ptr;
  }

  function to(uint _ptr, address _destination) internal pure returns (uint) {
    assembly {
      // Get end of buffer - 32 bytes plus the length stored at the pointer
      let len := add(0x20, mload(_ptr))
      // Push payee address to the end of the buffer
      mstore(add(_ptr, len), _destination)
      // Increment buffer length
      mstore(_ptr, len)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(add(0x40, _ptr), len)) {
        mstore(0x40, add(add(0x40, _ptr), len))
      }
    }
    return _ptr;
  }
}
