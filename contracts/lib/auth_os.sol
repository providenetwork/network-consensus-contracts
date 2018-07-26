pragma solidity ^0.4.23;

// File: tmp/RegistryInterface.sol

interface RegistryInterface {
  function getLatestVersion(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name)
      external view returns (bytes32 latest_name);
  function getVersionImplementation(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name, bytes32 version_name)
      external view returns (address index, bytes4[] selectors, address[] implementations);
}

// File: tmp/AbstractStorage.sol

contract AbstractStorage {

  // Special storage locations - applications can read from 0x0 to get the execution id, and 0x20
  // to get the sender from which the call originated
  bytes32 private exec_id;
  address private sender;

  // Keeps track of the number of applicaions initialized, so that each application has a unique execution id
  uint private nonce;

  /// EVENTS ///

  event ApplicationInitialized(bytes32 indexed execution_id, address indexed index, address script_exec);
  event ApplicationExecution(bytes32 indexed execution_id, address indexed script_target);
  event DeliveredPayment(bytes32 indexed execution_id, address indexed destination, uint amount);

  /// CONSTANTS ///

  // STORAGE LOCATIONS //

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');
  bytes32 internal constant APP_IDX_ADDR = keccak256('index');

  // ACTION REQUESTORS //

  bytes4 internal constant EMITS = bytes4(keccak256('Emit((bytes32[],bytes)[])'));
  bytes4 internal constant STORES = bytes4(keccak256('Store(bytes32[])'));
  bytes4 internal constant PAYS = bytes4(keccak256('Pay(bytes32[])'));
  bytes4 internal constant THROWS = bytes4(keccak256('Error(string)'));

  // SELECTORS //

  bytes4 internal constant REG_APP
      = bytes4(keccak256('registerApp(bytes32,address,bytes4[],address[])'));
  bytes4 internal constant REG_APP_VER
      = bytes4(keccak256('registerAppVersion(bytes32,bytes32,address,bytes4[],address[])'));

  // Creates an instance of a registry application and returns the execution id
  function createRegistry(address _registry_idx, address _implementation) external returns (bytes32) {
    bytes32 new_exec_id = keccak256(++nonce);
    put(new_exec_id, keccak256(msg.sender, EXEC_PERMISSIONS), bytes32(1));
    put(new_exec_id, APP_IDX_ADDR, bytes32(_registry_idx));
    put(new_exec_id, keccak256(REG_APP, 'implementation'), bytes32(_implementation));
    put(new_exec_id, keccak256(REG_APP_VER, 'implementation'), bytes32(_implementation));
    emit ApplicationInitialized(new_exec_id, _registry_idx, msg.sender);
    return new_exec_id;
  }

  /// APPLICATION INSTANCE INITIALIZATION ///

  /*
  Executes an initialization function of an application, generating a new exec id that will be associated with that address

  @param _sender: The sender of the transaction, as reported by the script exec contract
  @param _application: The target application to which the calldata will be forwarded
  @param _calldata: The calldata to forward to the application
  @return new_exec_id: A new, unique execution id paired with the created instance of the application
  @return version: The name of the version of the instance
  */
  function createInstance(address _sender, bytes32 _app_name, address _provider, bytes32 _registry_id, bytes _calldata) external payable returns (bytes32 new_exec_id, bytes32 version) {
    // Ensure valid input -
    require(_sender != 0 && _app_name != 0 && _provider != 0 && _registry_id != 0 && _calldata.length >= 4, 'invalid input');

    // Create new exec id by incrementing the nonce -
    new_exec_id = keccak256(++nonce);

    // Sanity check - verify that this exec id is not linked to an existing application -
    assert(getIndex(new_exec_id) == address(0));

    // Set the allowed addresses and selectors for the new instance, from the script registry -
    address index;
    (index, version) = setImplementation(new_exec_id, _app_name, _provider, _registry_id);

    // Set the exec id and sender addresses for the target application -
    setContext(new_exec_id, _sender);

    // Execute application, create a new exec id, and commit the returned data to storage -
    require(address(index).delegatecall(_calldata) == false, 'Unsafe execution');
    // Get data returned from call revert and perform requested actions -
    executeAppReturn(new_exec_id);

    // Emit event
    emit ApplicationInitialized(new_exec_id, index, msg.sender);

    // If execution reaches this point, newly generated exec id should be valid -
    assert(new_exec_id != bytes32(0));

    // Ensure that any additional balance is transferred back to the sender -
    if (address(this).balance > 0)
      address(msg.sender).transfer(address(this).balance);
  }

  /*
  Executes an initialized application associated with the given exec id, under the sender's address and with
  the given calldata

  @param _sender: The address reported as the call sender by the script exec contract
  @param _exec_id: The execution id corresponding to an instance of the application
  @param _calldata: The calldata to forward to the application
  @return n_emitted: The number of events emitted on behalf of the application
  @return n_paid: The number of destinations ETH was forwarded to on behalf of the application
  @return n_stored: The number of storage slots written to on behalf of the application
  */
  function exec(address _sender, bytes32 _exec_id, bytes _calldata) external payable returns (uint n_emitted, uint n_paid, uint n_stored) {
    // Ensure valid input and input size - minimum 4 bytes
    require(_calldata.length >= 4 && _sender != address(0) && _exec_id != bytes32(0));

    // Get the target address associated with the given exec id
    address target = getTarget(_exec_id, getSelector(_calldata));
    require(target != address(0), 'Uninitialized application');

    // Set the exec id and sender addresses for the target application -
    setContext(_exec_id, _sender);

    // Execute application and commit returned data to storage -
    require(address(target).delegatecall(_calldata) == false, 'Unsafe execution');
    (n_emitted, n_paid, n_stored) = executeAppReturn(_exec_id);

    // If no events were emitted, no wei was forwarded, and no storage was changed, revert -
    if (n_emitted == 0 && n_paid == 0 && n_stored == 0)
      revert('No state change occured');

    // Emit event -
    emit ApplicationExecution(_exec_id, target);

    // Ensure that any additional balance is transferred back to the sender -
    if (address(this).balance > 0)
      address(msg.sender).transfer(address(this).balance);
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
    (ptr_bound, _ptr) = getReturnedData();
    // If the application reverted with an error, we can check directly for its selector -
    if (getAction(_ptr) == THROWS) {
      // Execute THROWS request
      doThrow(_ptr);
      // doThrow should revert, so we should never reach this point
      assert(false);
    }

    // Ensure there are at least 64 bytes stored at the pointer
    require(ptr_bound >= _ptr + 64, 'Malformed returndata - invalid size');
    _ptr += 64;

    // Iterate over returned data and execute actions
    bytes4 action;
    while (_ptr <= ptr_bound && (action = getAction(_ptr)) != 0x0) {
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
        (_ptr, n_paid) = doPay(_exec_id, _ptr, ptr_bound);
        // If no destinations recieved ETH, returndata is malformed: throw
        require(n_paid != 0, 'Unfulfilled action: PAYS');
      } else {
        // Unrecognized action requested. returndata is malformed: throw
        revert('Malformed returndata - unknown action');
      }
    }
    assert(n_emitted != 0 || n_paid != 0 || n_stored != 0);
  }

  /// HELPERS ///

  /*
  Reads application information from the script registry, and sets up permissions for the new instance's various functions

  @param _new_exec_id: The execution id being created, for which permissions will be registered
  @param _app_name: The name of the new application instance - corresponds to an application registered by the provider under that name
  @param _provider: The address of the account that registered an application under the given name
  @param _registry_id: The exec id of the registry from which the information will be read
  */
  function setImplementation(bytes32 _new_exec_id, bytes32 _app_name, address _provider, bytes32 _registry_id) internal returns (address index, bytes32 version) {
    // Get the index address for the registry app associated with the passed-in exec id
    index = getIndex(_registry_id);
    require(index != address(0) && index != address(this), 'Registry application not found');
    // Get the name of the latest version from the registry app at the given address
    version = RegistryInterface(index).getLatestVersion(
      address(this), _registry_id, _provider, _app_name
    );
    // Ensure the version name is valid -
    require(version != bytes32(0), 'Invalid version name');

    // Get the allowed selectors and addresses for the new instance from the registry app
    bytes4[] memory selectors;
    address[] memory implementations;
    (index, selectors, implementations) = RegistryInterface(index).getVersionImplementation(
      address(this), _registry_id, _provider, _app_name, version
    );
    // Ensure a valid index address for the new instance -
    require(index != address(0), 'Invalid index address');
    // Ensure a nonzero number of allowed selectors and implementing addresses -
    require(selectors.length == implementations.length && selectors.length != 0, 'Invalid implementation length');

    // Set the index address for the new instance -
    bytes32 seed = APP_IDX_ADDR;
    put(_new_exec_id, seed, bytes32(index));
    // Loop over implementing addresses, and map each function selector to its corresponding address for the new instance
    for (uint i = 0; i < selectors.length; i++) {
      require(selectors[i] != 0 && implementations[i] != 0, 'invalid input - expected nonzero implementation');
      seed = keccak256(selectors[i], 'implementation');
      put(_new_exec_id, seed, bytes32(implementations[i]));
    }

    return (index, version);
  }

  // Returns the index address of an application using a given exec id, or 0x0
  // if the instance does not exist
  function getIndex(bytes32 _exec_id) public view returns (address) {
    bytes32 seed = APP_IDX_ADDR;
    function (bytes32, bytes32) view returns (address) getter;
    assembly { getter := readMap }
    return getter(_exec_id, seed);
  }

  // Returns the address to which calldata with the given selector will be routed
  function getTarget(bytes32 _exec_id, bytes4 _selector) public view returns (address) {
    bytes32 seed = keccak256(_selector, 'implementation');
    function (bytes32, bytes32) view returns (address) getter;
    assembly { getter := readMap }
    return getter(_exec_id, seed);
  }

  struct Map { mapping(bytes32 => bytes32) inner; }

  // Receives a storage pointer and returns the value mapped to the seed at that pointer
  function readMap(Map storage _map, bytes32 _seed) internal view returns (bytes32) {
    return _map.inner[_seed];
  }

  // Maps the seed to the value within the execution id's storage
  function put(bytes32 _exec_id, bytes32 _seed, bytes32 _val) internal {
    function (bytes32, bytes32, bytes32) puts;
    assembly { puts := putMap }
    puts(_exec_id, _seed, _val);
  }

  // Receives a storage pointer and maps the seed to the value at that pointer
  function putMap(Map storage _map, bytes32 _seed, bytes32 _val) internal {
    _map.inner[_seed] = _val;
  }

  /// APPLICATION EXECUTION ///

  function getSelector(bytes memory _calldata) internal pure returns (bytes4 sel) {
    assembly {
      sel := and(
        mload(add(0x20, _calldata)),
        0xffffffff00000000000000000000000000000000000000000000000000000000
      )
    }
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
      // Copy returned data to pointer location
      returndatacopy(_returndata_ptr, 0, returndatasize)
      // Get maximum memory location value for returndata
      ptr_bounds := add(_returndata_ptr, returndatasize)
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
    assembly { length := mload(_ptr) }
  }

  // Executes the THROWS action, reverting any returned data back to the caller
  function doThrow(uint _ptr) internal pure {
    assert(getAction(_ptr) == THROWS);
    assembly { revert(_ptr, returndatasize) }
  }

  /*
  Parses and executes a PAYS action copied from returndata and located at the pointer
  A PAYS action provides a set of addresses and corresponding amounts of ETH to send to those
  addresses. The sender must ensure the call has sufficient funds, or the call will fail
  PAYS actions follow a format of: [amt_0][address_0]...[amt_n][address_n]

  @param _ptr: A pointer in memory to an application's returned payment request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @return ptr: An updated pointer, pointing to the end of the PAYS action request in memory
  @return n_paid: The number of destinations paid out to from the returned PAYS request
  */
  function doPay(bytes32 _exec_id, uint _ptr, uint _ptr_bound) internal returns (uint ptr, uint n_paid) {
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
  STORES actions follow a format of: [location_0][val_0]...[location_n][val_n]

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
        location := mload(_ptr)
        value := mload(add(0x20, _ptr))
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

  // Sets the execution id and sender address in special storage locations, so that
  // they are able to be read by the target application
  function setContext(bytes32 _exec_id, address _sender) internal {
    // Ensure the exec id and sender are nonzero
    assert(_exec_id != bytes32(0) && _sender != address(0));
    exec_id = _exec_id;
    sender = _sender;
  }

  // Stores data to a given location, with a key (exec id)
  function store(bytes32 _exec_id, bytes32 _location, bytes32 _data) internal {
    // Get true location to store data to - hash of location hashed with exec id
    _location = keccak256(_location, _exec_id);
    // Store data at location
    assembly { sstore(_location, _data) }
  }

  // STORAGE READS //

  /*
  Returns data stored at a given location
  @param _location: The address to get data from
  @return data: The data stored at the location after hashing
  */
  function read(bytes32 _exec_id, bytes32 _location) public view returns (bytes32 data_read) {
    _location = keccak256(_location, _exec_id);
    assembly { data_read := sload(_location) }
  }

  /*
  Returns data stored in several nonconsecutive locations
  @param _locations: A dynamic array of storage locations to read from
  @return data_read: The corresponding data stored in the requested locations
  */
  function readMulti(bytes32 _exec_id, bytes32[] _locations) public view returns (bytes32[] data_read) {
    data_read = new bytes32[](_locations.length);
    for (uint i = 0; i < _locations.length; i++) {
      bytes32 location = keccak256(_locations[i], _exec_id);
      bytes32 val;
      assembly { val := sload(location) }
      data_read[i] = val;
    }
  }
}

// File: tmp/SafeMath.sol

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "Overflow - Multiplication");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Underflow - Subtraction");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "Overflow - Addition");
    return c;
  }
}

// File: tmp/Contract.sol

library Contract {

  using SafeMath for uint;

  // Modifiers: //

  // Runs two functions before and after a function -
  modifier conditions(function () pure first, function () pure last) {
    first();
    _;
    last();
  }

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');

  // Sets up contract execution - reads execution id and sender from storage and
  // places in memory, creating getters. Calling this function should be the first
  // action an application does as part of execution, as it sets up memory for
  // execution. Additionally, application functions in the main file should be
  // external, so that memory is not touched prior to calling this function.
  // The 3rd slot allocated will hold a pointer to a storage buffer, which will
  // be reverted to abstract storage to store data, emit events, and forward
  // wei on behalf of the application.
  function authorize(address _script_exec) internal view {
    // No memory should have been allocated yet - expect the free memory pointer
    // to point to 0x80 - and throw if it does not
    require(freeMem() == 0x80, "Memory allocated prior to execution");
    // Next, set up memory for execution
    bytes32 perms = EXEC_PERMISSIONS;
    assembly {
      mstore(0x80, sload(0))     // Execution id, read from storage
      mstore(0xa0, sload(1))     // Original sender address, read from storage
      mstore(0xc0, 0)            // Pointer to storage buffer
      mstore(0xe0, 0)            // Bytes4 value of the current action requestor being used
      mstore(0x100, 0)           // Enum representing the next type of function to be called (when pushing to buffer)
      mstore(0x120, 0)           // Number of storage slots written to in buffer
      mstore(0x140, 0)           // Number of events pushed to buffer
      mstore(0x160, 0)           // Number of payment destinations pushed to buffer

      // Update free memory pointer -
      mstore(0x40, 0x180)
    }
    // Ensure that the sender and execution id returned from storage are nonzero -
    assert(execID() != bytes32(0) && sender() != address(0));

    // Check that the sender is authorized as a script exec contract for this exec id
    bool authorized;
    assembly {
      // Place the script exec address at 0, and the exec permissions seed after it
      mstore(0, _script_exec)
      mstore(0x20, perms)
      // Hash the resulting 0x34 bytes, and place back into memory at 0
      mstore(0, keccak256(0x0c, 0x34))
      // Place the exec id after the hash -
      mstore(0x20, mload(0x80))
      // Hash the previous hash with the execution id, and check the result
      authorized := sload(keccak256(0, 0x40))
    }
    if (!authorized)
      revert("Sender is not authorized as a script exec address");
  }

  // Sets up contract execution when initializing an instance of the application
  // First, reads execution id and sender from storage (execution id should be 0xDEAD),
  // then places them in memory, creating getters. Calling this function should be the first
  // action an application does as part of execution, as it sets up memory for
  // execution. Additionally, application functions in the main file should be
  // external, so that memory is not touched prior to calling this function.
  // The 3rd slot allocated will hold a pointer to a storage buffer, which will
  // be reverted to abstract storage to store data, emit events, and forward
  // wei on behalf of the application.
  function initialize() internal view {
    // No memory should have been allocated yet - expect the free memory pointer
    // to point to 0x80 - and throw if it does not
    require(freeMem() == 0x80, "Memory allocated prior to execution");
    // Next, set up memory for execution
    assembly {
      mstore(0x80, sload(0))     // Execution id, read from storage
      mstore(0xa0, sload(1))     // Original sender address, read from storage
      mstore(0xc0, 0)            // Pointer to storage buffer
      mstore(0xe0, 0)            // Bytes4 value of the current action requestor being used
      mstore(0x100, 0)           // Enum representing the next type of function to be called (when pushing to buffer)
      mstore(0x120, 0)           // Number of storage slots written to in buffer
      mstore(0x140, 0)           // Number of events pushed to buffer
      mstore(0x160, 0)           // Number of payment destinations pushed to buffer

      // Update free memory pointer -
      mstore(0x40, 0x180)
    }
    // Ensure that the sender and execution id returned from storage are expected values -
    assert(execID() != bytes32(0) && sender() != address(0));
  }

  // Calls the passed-in function, performing a memory state check before and after the check
  // is executed.
  function checks(function () view _check) conditions(validState, validState) internal view {
    _check();
  }

  // Calls the passed-in function, performing a memory state check before and after the check
  // is executed.
  function checks(function () pure _check) conditions(validState, validState) internal pure {
    _check();
  }

  // Ensures execution completed successfully, and reverts the created storage buffer
  // back to the sender.
  function commit() conditions(validState, none) internal pure {
    // Check value of storage buffer pointer - should be at least 0x180
    bytes32 ptr = buffPtr();
    require(ptr >= 0x180, "Invalid buffer pointer");

    assembly {
      // Get the size of the buffer
      let size := mload(add(0x20, ptr))
      mstore(ptr, 0x20) // Place dynamic data offset before buffer
      // Revert to storage
      revert(ptr, add(0x40, size))
    }
  }

  // Helpers: //

  // Checks to ensure the application was correctly executed -
  function validState() private pure {
    if (freeMem() < 0x180)
      revert('Expected Contract.execute()');

    if (buffPtr() != 0 && buffPtr() < 0x180)
      revert('Invalid buffer pointer');

    assert(execID() != bytes32(0) && sender() != address(0));
  }

  // Returns a pointer to the execution storage buffer -
  function buffPtr() private pure returns (bytes32 ptr) {
    assembly { ptr := mload(0xc0) }
  }

  // Returns the location pointed to by the free memory pointer -
  function freeMem() private pure returns (bytes32 ptr) {
    assembly { ptr := mload(0x40) }
  }

  // Returns the current storage action
  function currentAction() private pure returns (bytes4 action) {
    if (buffPtr() == bytes32(0))
      return bytes4(0);

    assembly { action := mload(0xe0) }
  }

  // If the current action is not storing, reverts
  function isStoring() private pure {
    if (currentAction() != STORES)
      revert('Invalid current action - expected STORES');
  }

  // If the current action is not emitting, reverts
  function isEmitting() private pure {
    if (currentAction() != EMITS)
      revert('Invalid current action - expected EMITS');
  }

  // If the current action is not paying, reverts
  function isPaying() private pure {
    if (currentAction() != PAYS)
      revert('Invalid current action - expected PAYS');
  }

  // Initializes a storage buffer in memory -
  function startBuffer() private pure {
    assembly {
      // Get a pointer to free memory, and place at 0xc0 (storage buffer pointer)
      let ptr := msize()
      mstore(0xc0, ptr)
      // Clear bytes at pointer -
      mstore(ptr, 0)            // temp ptr
      mstore(add(0x20, ptr), 0) // buffer length
      // Update free memory pointer -
      mstore(0x40, add(0x40, ptr))
      // Set expected next function to 'NONE' -
      mstore(0x100, 1)
    }
  }

  // Checks whether or not it is valid to create a STORES action request -
  function validStoreBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not 'storing', and that the buffer has not already
    // completed a STORES action -
    if (stored() != 0 || currentAction() == STORES)
      revert('Duplicate request - stores');
  }

  // Checks whether or not it is valid to create an EMITS action request -
  function validEmitBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not 'emitting', and that the buffer has not already
    // completed an EMITS action -
    if (emitted() != 0 || currentAction() == EMITS)
      revert('Duplicate request - emits');
  }

  // Checks whether or not it is valid to create a PAYS action request -
  function validPayBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not 'paying', and that the buffer has not already
    // completed an PAYS action -
    if (paid() != 0 || currentAction() == PAYS)
      revert('Duplicate request - pays');
  }

  // Placeholder function when no pre or post condition for a function is needed
  function none() private pure { }

  // Runtime getters: //

  // Returns the execution id from memory -
  function execID() internal pure returns (bytes32 exec_id) {
    assembly { exec_id := mload(0x80) }
    require(exec_id != bytes32(0), "Execution id overwritten, or not read");
  }

  // Returns the original sender from memory -
  function sender() internal pure returns (address addr) {
    assembly { addr := mload(0xa0) }
    require(addr != address(0), "Sender address overwritten, or not read");
  }

  // Reading from storage: //

  // Reads from storage, resolving the passed-in location to its true location in storage
  // by hashing with the exec id. Returns the data read from that location
  function read(bytes32 _location) internal view returns (bytes32 data) {
    data = keccak256(_location, execID());
    assembly { data := sload(data) }
  }

  // Storing data, emitting events, and forwarding payments: //

  bytes4 internal constant EMITS = bytes4(keccak256('Emit((bytes32[],bytes)[])'));
  bytes4 internal constant STORES = bytes4(keccak256('Store(bytes32[])'));
  bytes4 internal constant PAYS = bytes4(keccak256('Pay(bytes32[])'));
  bytes4 internal constant THROWS = bytes4(keccak256('Error(string)'));

  // Function enums -
  enum NextFunction {
    INVALID, NONE, STORE_DEST, VAL_SET, VAL_INC, VAL_DEC, EMIT_LOG, PAY_DEST, PAY_AMT
  }

  // Checks that a call pushing a storage destination to the buffer is expected and valid
  function validStoreDest() private pure {
    // Ensure that the next function expected pushes a storage destination -
    if (expected() != NextFunction.STORE_DEST)
      revert('Unexpected function order - expected storage destination to be pushed');

    // Ensure that the current buffer is pushing STORES actions -
    isStoring();
  }

  // Checks that a call pushing a storage value to the buffer is expected and valid
  function validStoreVal() private pure {
    // Ensure that the next function expected pushes a storage value -
    if (
      expected() != NextFunction.VAL_SET &&
      expected() != NextFunction.VAL_INC &&
      expected() != NextFunction.VAL_DEC
    ) revert('Unexpected function order - expected storage value to be pushed');

    // Ensure that the current buffer is pushing STORES actions -
    isStoring();
  }

  // Checks that a call pushing a payment destination to the buffer is expected and valid
  function validPayDest() private pure {
    // Ensure that the next function expected pushes a payment destination -
    if (expected() != NextFunction.PAY_DEST)
      revert('Unexpected function order - expected payment destination to be pushed');

    // Ensure that the current buffer is pushing PAYS actions -
    isPaying();
  }

  // Checks that a call pushing a payment amount to the buffer is expected and valid
  function validPayAmt() private pure {
    // Ensure that the next function expected pushes a payment amount -
    if (expected() != NextFunction.PAY_AMT)
      revert('Unexpected function order - expected payment amount to be pushed');

    // Ensure that the current buffer is pushing PAYS actions -
    isPaying();
  }

  // Checks that a call pushing an event to the buffer is expected and valid
  function validEvent() private pure {
    // Ensure that the next function expected pushes an event -
    if (expected() != NextFunction.EMIT_LOG)
      revert('Unexpected function order - expected event to be pushed');

    // Ensure that the current buffer is pushing EMITS actions -
    isEmitting();
  }

  // Begins creating a storage buffer - values and locations pushed will be committed
  // to storage at the end of execution
  function storing() conditions(validStoreBuff, isStoring) internal pure {
    bytes4 action_req = STORES;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the 'current action' slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      mstore(0xe0, action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the STORES action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (STORES) -
      mstore(0xe0, action_req)
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Sets a passed in location to a value passed in via 'to'
  function set(bytes32 _field) conditions(validStoreDest, validStoreVal) internal pure returns (bytes32) {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_SET
      mstore(0x100, 3)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
    return _field;
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32, bytes32 _val) conditions(validStoreVal, validStoreDest) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _val)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, uint _val) internal pure {
    to(_field, bytes32(_val));
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, address _val) internal pure {
    to(_field, bytes32(_val));
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, bool _val) internal pure {
    to(
      _field,
      _val ? bytes32(1) : bytes32(0)
    );
  }

  function increase(bytes32 _field) conditions(validStoreDest, validStoreVal) internal view returns (bytes32 val) {
    // Read value stored at the location in storage -
    val = keccak256(_field, execID());
    assembly {
      val := sload(val)
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_INC
      mstore(0x100, 4)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
    return val;
  }

  function decrease(bytes32 _field) conditions(validStoreDest, validStoreVal) internal view returns (bytes32 val) {
    // Read value stored at the location in storage -
    val = keccak256(_field, execID());
    assembly {
      val := sload(val)
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_DEC
      mstore(0x100, 5)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
    return val;
  }

  function by(bytes32 _val, uint _amt) conditions(validStoreVal, validStoreDest) internal pure {
    // Check the expected function type - if it is VAL_INC, perform safe-add on the value
    // If it is VAL_DEC, perform safe-sub on the value
    if (expected() == NextFunction.VAL_INC)
      _amt = _amt.add(uint(_val));
    else if (expected() == NextFunction.VAL_DEC)
      _amt = uint(_val).sub(_amt);
    else
      revert('Expected VAL_INC or VAL_DEC');

    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amt)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Decreases the value at some field by a maximum amount, and sets it to 0 if there will be underflow
  function byMaximum(bytes32 _val, uint _amt) conditions(validStoreVal, validStoreDest) internal pure {
    // Check the expected function type - if it is VAL_DEC, set the new amount to the difference of
    // _val and _amt, to a minimum of 0
    if (expected() == NextFunction.VAL_DEC) {
      if (uint(_val) > _amt)
        _amt = 0;
      else
        _amt = uint(_val).sub(_amt);
    } else {
      revert('Expected VAL_DEC');
    }

    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amt)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Begins creating an event log buffer - topics and data pushed will be emitted by
  // storage at the end of execution
  function emitting() conditions(validEmitBuff, isEmitting) internal pure {
    bytes4 action_req = EMITS;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the 'current action' slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      mstore(0xe0, action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the EMITS action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (EMITS) -
      mstore(0xe0, action_req)
      // Set the expected next function - EMIT_LOG
      mstore(0x100, 6)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  function log(bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 0 to the end of the buffer - event will have 0 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 0)
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x40, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x40 plus the original length
        mstore(ptr, add(0x40, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x40, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0x60, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0x60 plus the original length
        mstore(ptr, add(0x60, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  function log(bytes32[1] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 1 to the end of the buffer - event will have 1 topic
      mstore(add(0x20, add(ptr, mload(ptr))), 1)
      // Push topic to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x60, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x60 plus the original length
        mstore(ptr, add(0x60, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x60, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0x80, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0x80 plus the original length
        mstore(ptr, add(0x80, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  function log(bytes32[2] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 2 to the end of the buffer - event will have 2 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 2)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x80, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x80 plus the original length
        mstore(ptr, add(0x80, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x80, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xa0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xa0 plus the original length
        mstore(ptr, add(0xa0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  function log(bytes32[3] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 3 to the end of the buffer - event will have 3 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 3)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      mstore(add(0x80, add(ptr, mload(ptr))), mload(add(0x40, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0xa0, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0xa0 plus the original length
        mstore(ptr, add(0xa0, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0xa0, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xc0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xc0 plus the original length
        mstore(ptr, add(0xc0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  function log(bytes32[4] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 4 to the end of the buffer - event will have 4 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 4)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      mstore(add(0x80, add(ptr, mload(ptr))), mload(add(0x40, _topics)))
      mstore(add(0xa0, add(ptr, mload(ptr))), mload(add(0x60, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0xc0, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0xc0 plus the original length
        mstore(ptr, add(0xc0, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0xc0, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xe0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xe0 plus the original length
        mstore(ptr, add(0xe0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Begins creating a storage buffer - destinations entered will be forwarded wei
  // before the end of execution
  function paying() conditions(validPayBuff, isPaying) internal pure {
    bytes4 action_req = PAYS;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the 'current action' slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      mstore(0xe0, action_req)
      // Push '0' to the end of the 4 bytes just pushed - this will be the length of the PAYS action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (PAYS) -
      mstore(0xe0, action_req)
      // Set the expected next function - PAY_AMT
      mstore(0x100, 8)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Pushes an amount of wei to forward to the buffer
  function pay(uint _amount) conditions(validPayAmt, validPayDest) internal pure returns (uint) {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push payment amount to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amount)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - PAY_DEST
      mstore(0x100, 7)
      // Increment PAYS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of payment destinations to be pushed to -
      mstore(0x160, add(1, mload(0x160)))
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
    return _amount;
  }

  // Push an address to forward wei to, to the buffer
  function toAcc(uint, address _dest) conditions(validPayDest, validPayAmt) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push payment destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _dest)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - PAY_AMT
      mstore(0x100, 8)
      // If the free-memory pointer does not point beyond the buffer's current size, update it
      if lt(mload(0x40), add(0x20, add(ptr, mload(ptr)))) {
        mstore(0x40, add(0x20, add(ptr, mload(ptr))))
      }
    }
  }

  // Returns the enum representing the next expected function to be called -
  function expected() private pure returns (NextFunction next) {
    assembly { next := mload(0x100) }
  }

  // Returns the number of events pushed to the storage buffer -
  function emitted() internal pure returns (uint num_emitted) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number emitted from buffer -
    assembly { num_emitted := mload(0x140) }
  }

  // Returns the number of storage slots pushed to the storage buffer -
  function stored() internal pure returns (uint num_stored) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number stored from buffer -
    assembly { num_stored := mload(0x120) }
  }

  // Returns the number of payment destinations and amounts pushed to the storage buffer -
  function paid() internal pure returns (uint num_paid) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number paid from buffer -
    assembly { num_paid := mload(0x160) }
  }
}

// File: tmp/Provider.sol

library Provider {

  using Contract for *;

  // Returns the location of a provider's list of registered applications in storage
  function registeredApps() internal pure returns (bytes32 location) {
    location = keccak256(bytes32(Contract.sender()), 'app_list');
  }

  // Returns the location of a registered app's name under a provider
  function appBase(bytes32 _app) internal pure returns (bytes32 location) {
    location = keccak256(_app, keccak256(bytes32(Contract.sender()), 'app_base'));
  }

  // Returns the location of an app's list of versions
  function appVersionList(bytes32 _app) internal pure returns (bytes32 location) {
    location = keccak256('versions', appBase(_app));
  }

  // Returns the location of a version's name
  function versionBase(bytes32 _app, bytes32 _version) internal pure returns (bytes32 location) {
    location = keccak256(_version, 'version', appBase(_app));
  }

  // Returns the location of a registered app's index address under a provider
  function versionIndex(bytes32 _app, bytes32 _version) internal pure returns (bytes32 location) {
    location = keccak256('index', versionBase(_app, _version));
  }

  // Returns the location of an app's function selectors, registered under a provider
  function versionSelectors(bytes32 _app, bytes32 _version) internal pure returns (bytes32 location) {
    location = keccak256('selectors', versionBase(_app, _version));
  }

  // Returns the location of an app's implementing addresses, registered under a provider
  function versionAddresses(bytes32 _app, bytes32 _version) internal pure returns (bytes32 location) {
    location = keccak256('addresses', versionBase(_app, _version));
  }

  // Returns the location of the version before the current version
  function previousVersion(bytes32 _app, bytes32 _version) internal pure returns (bytes32 location) {
    location = keccak256("previous version", versionBase(_app, _version));
  }

  // Returns storage location of appversion list at a specific index
  function appVersionListAt(bytes32 _app, uint _index) internal pure returns (bytes32 location) {
    location = bytes32((32 * _index) + uint(appVersionList(_app)));
  }

  // Registers an application under a given name for the sender
  function registerApp(bytes32 _app, address _index, bytes4[] _selectors, address[] _implementations) external view {
    // Begin execution -
    Contract.authorize(msg.sender);

    // Throw if the name has already been registered
    if (Contract.read(appBase(_app)) != bytes32(0))
      revert("app is already registered");

    if (_selectors.length != _implementations.length || _selectors.length == 0)
      revert("invalid input arrays");

    // Start storing values
    Contract.storing();

    // Store the app name in the list of registered app names
    uint num_registered_apps = uint(Contract.read(registeredApps()));

    Contract.increase(registeredApps()).by(uint(1));

    Contract.set(
      bytes32(32 * (num_registered_apps + 1) + uint(registeredApps()))
    ).to(_app);

    // Store the app name at app_base
    Contract.set(appBase(_app)).to(_app);

    // Set the first version to this app
    Contract.set(versionBase(_app, _app)).to(_app);

    // Push the app to its own version list as the first version
    Contract.set(appVersionList(_app)).to(uint(1));

    Contract.set(
      bytes32(32 + uint(appVersionList(_app)))
    ).to(_app);

    // Sets app index
    Contract.set(versionIndex(_app, _app)).to(_index);

    // Loop over the passed-in selectors and addresses and store them each at
    // version_selectors/version_addresses, respectively
    Contract.set(versionSelectors(_app, _app)).to(_selectors.length);
    Contract.set(versionAddresses(_app, _app)).to(_implementations.length);
    for (uint i = 0; i < _selectors.length; i++) {
      Contract.set(bytes32(32 * (i + 1) + uint(versionSelectors(_app, _app)))).to(_selectors[i]);
      Contract.set(bytes32(32 * (i + 1) + uint(versionAddresses(_app, _app)))).to(_implementations[i]);
    }

    // Set previous version to 0
    Contract.set(previousVersion(_app, _app)).to(uint(0));

    // End execution and commit state changes to storage -
    Contract.commit();
  }

  function registerAppVersion(bytes32 _app, bytes32 _version, address _index, bytes4[] _selectors, address[] _implementations) external view {
    // Begin execution -
    Contract.authorize(msg.sender);

    // Throw if the app has not been registered
    // Throw if the version has already been registered (check app_base)
    if (Contract.read(appBase(_app)) == bytes32(0))
      revert("App has not been registered");

    if (Contract.read(versionBase(_app, _version)) != bytes32(0))
      revert("Version already exists");

    if (
      _selectors.length != _implementations.length ||
      _selectors.length == 0
    ) revert("Invalid input array lengths");

    // Begin storing values
    Contract.storing();

    // Store the version name at version_base
    Contract.set(versionBase(_app, _version)).to(_version);

    // Push the version to the app's version list
    uint num_versions = uint(Contract.read(appVersionList(_app)));
    Contract.set(appVersionListAt(_app, (num_versions + 1))).to(_version);
    Contract.set(appVersionList(_app)).to(num_versions + 1);

    // Store the index at version_index
    Contract.set(versionIndex(_app, _version)).to(_index);

    // Loop over the passed-in selectors and addresses and store them each at
    // version_selectors/version_addresses, respectively
    Contract.set(versionSelectors(_app, _version)).to(_selectors.length);
    Contract.set(versionAddresses(_app, _version)).to(_implementations.length);
    for (uint i = 0; i < _selectors.length; i++) {
      Contract.set(bytes32(32 * (i + 1) + uint(versionSelectors(_app, _version)))).to(_selectors[i]);
      Contract.set(bytes32(32 * (i + 1) + uint(versionAddresses(_app, _version)))).to(_implementations[i]);
    }

    // Set the version's previous version
    bytes32 prev_version = Contract.read(bytes32(32 * num_versions + uint(appVersionList(_app))));
    Contract.set(previousVersion(_app, _version)).to(prev_version);

    // End execution and commit state changes to storage -
    Contract.commit();
  }

}

// File: tmp/StorageInterface.sol

interface StorageInterface {
  function getTarget(bytes32 exec_id, bytes4 selector)
      external view returns (address implementation);
  function getIndex(bytes32 exec_id) external view returns (address index);
  function createInstance(address sender, bytes32 app_name, address provider, bytes32 registry_exec_id, bytes calldata)
      external payable returns (bytes32 instance_exec_id, bytes32 version);
  function createRegistry(address index, address implementation) external returns (bytes32 exec_id);
  function exec(address sender, bytes32 exec_id, bytes calldata)
      external payable returns (uint emitted, uint paid, uint stored);
}

// File: tmp/ScriptExec.sol

contract ScriptExec {

  /// DEFAULT VALUES ///

  address public app_storage;
  address public provider;
  bytes32 public registry_exec_id;
  address public exec_admin;

  /// APPLICATION INSTANCE METADATA ///

  struct Instance {
    address current_provider;
    bytes32 current_registry_exec_id;
    bytes32 app_exec_id;
    bytes32 app_name;
    bytes32 version_name;
  }

  // Maps the execution ids of deployed instances to the address that deployed them -
  mapping (bytes32 => address) public deployed_by;
  // Maps the execution ids of deployed instances to a struct containing their metadata -
  mapping (bytes32 => Instance) public instance_info;
  // Maps an address that deployed app instances to metadata about the deployed instance -
  mapping (address => Instance[]) public deployed_instances;
  // Maps an application name to the exec ids under which it is deployed -
  mapping (bytes32 => bytes32[]) public app_instances;

  /// EVENTS ///

  event AppInstanceCreated(address indexed creator, bytes32 indexed execution_id, bytes32 app_name, bytes32 version_name);

  // Modifier - The sender must be the contract administrator
  modifier onlyAdmin() {
    require(msg.sender == exec_admin);
    _;
  }

  // Payable function - for abstract storage refunds
  function () public payable { }


  /*
  Configure various defaults for a script exec contract
  @param _exec_admin: A privileged address, able to set the target provider and registry exec id
  @param _app_storage: The address to which applications will be stored
  @param _provider: The address under which applications have been initialized
  */
  function configure(address _exec_admin, address _app_storage, address _provider) public {
    require(_app_storage != 0, 'Invalid input');
    exec_admin = _exec_admin;
    app_storage = _app_storage;
    provider = _provider;

    if (exec_admin == 0)
      exec_admin = msg.sender;
  }

  /// APPLICATION EXECUTION ///

  /*
  Executes an application using its execution id and storage address.

  @param _exec_id: The instance exec id, which will route the calldata to the appropriate destination
  @param _calldata: The calldata to forward to the application
  @return success: Whether execution succeeded or not
  */
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success) {
    // Call 'exec' in AbstractStorage, passing in the sender's address, the app exec id, and the calldata to forward -
    StorageInterface(app_storage).exec.value(msg.value)(msg.sender, _exec_id, _calldata);

    // Get returned data
    success = checkReturn();
    // If execution failed, revert -
    require(success, 'Execution failed');

    // Transfer any returned wei back to the sender
    address(msg.sender).transfer(address(this).balance);
  }

  // Checks data returned by an application and returns whether or not the execution changed state
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

  /*
  Initializes an instance of an application. Uses default app provider and registry app.
  Uses latest app version by default.
  @param _app_name: The name of the application to initialize
  @param _init_calldata: Calldata to be forwarded to the application's initialization function
  @return exec_id: The execution id (within the application's storage) of the created application instance
  @return version: The name of the version of the instance
  */
  function createAppInstance(bytes32 _app_name, bytes _init_calldata) external returns (bytes32 exec_id, bytes32 version) {
    require(_app_name != 0 && _init_calldata.length >= 4, 'invalid input');
    (exec_id, version) = StorageInterface(app_storage).createInstance(
      msg.sender, _app_name, provider, registry_exec_id, _init_calldata
    );
    // Set various app metadata values -
    deployed_by[exec_id] = msg.sender;
    app_instances[_app_name].push(exec_id);
    Instance memory inst = Instance(
      provider, registry_exec_id, exec_id, _app_name, version
    );
    instance_info[exec_id] = inst;
    deployed_instances[msg.sender].push(inst);
    // Emit event -
    emit AppInstanceCreated(msg.sender, exec_id, _app_name, version);
  }

  /// ADMIN FUNCTIONS ///

  /*
  Allows the exec admin to set the registry exec id from which applications will be initialized -
  @param _exec_id: The new exec id from which applications will be initialized
  */
  function setRegistryExecID(bytes32 _exec_id) public onlyAdmin() {
    registry_exec_id = _exec_id;
  }

  /*
  Allows the exec admin to set the provider from which applications will be initialized in the given registry exec id
  @param _provider: The address under which applications to initialize are registered
  */
  function setProvider(address _provider) public onlyAdmin() {
    provider = _provider;
  }

  // Allows the admin to set a new admin address
  function setAdmin(address _admin) public onlyAdmin() {
    require(_admin != 0);
    exec_admin = _admin;
  }

  /// STORAGE GETTERS ///

  // Returns a list of execution ids under which the given app name was deployed
  function getInstances(bytes32 _app_name) public view returns (bytes32[] memory) {
    return app_instances[_app_name];
  }

  /*
  Returns the number of instances an address has created
  @param _deployer: The address that deployed the instances
  @return uint: The number of instances deployed by the deployer
  */
  function getDeployedLength(address _deployer) public view returns (uint) {
    return deployed_instances[_deployer].length;
  }

  // The function selector for a simple registry 'registerApp' function
  bytes4 internal constant REGISTER_APP_SEL = bytes4(keccak256('registerApp(bytes32,address,bytes4[],address[])'));

  /*
  Returns the index address and implementing address for the simple registry app set as the default
  @return indx: The index address for the registry application - contains getters for the Registry, as well as its init funciton
  @return implementation: The address implementing the registry's functions
  */
  function getRegistryImplementation() public view returns (address indx, address implementation) {
    indx = StorageInterface(app_storage).getIndex(registry_exec_id);
    implementation = StorageInterface(app_storage).getTarget(registry_exec_id, REGISTER_APP_SEL);
  }

  /*
  Returns the functions and addresses implementing those functions that make up an application under the give execution id
  @param _exec_id: The execution id that represents the application in storage
  @return index: The index address of the instance - holds the app's getter functions and init functions
  @return functions: A list of function selectors supported by the application
  @return implementations: A list of addresses corresponding to the function selectors, where those selectors are implemented
  */
  function getInstanceImplementation(bytes32 _exec_id) public view
  returns (address index, bytes4[] memory functions, address[] memory implementations) {
    Instance memory app = instance_info[_exec_id];
    index = StorageInterface(app_storage).getIndex(app.current_registry_exec_id);
    (index, functions, implementations) = RegistryInterface(index).getVersionImplementation(
      app_storage, app.current_registry_exec_id, app.current_provider, app.app_name, app.version_name
    );
  }
}

// File: tmp/RegistryExec.sol

contract RegistryExec is ScriptExec {

  struct Registry {
    address index;
    address implementation;
  }

  // Maps execution ids to its registry app metadata
  mapping (bytes32 => Registry) public registry_instance_info;
  // Maps address to list of deployed Registry instances
  mapping (address => Registry[]) public deployed_registry_instances;

  /// EVENTS ///

  event RegistryInstanceCreated(address indexed creator, bytes32 indexed execution_id, address index, address implementation);

  /// REGISTRY FUNCTIONS ///

  /*
  Creates an instance of a registry application and returns its execution id
  @param _index: The index file of the registry app (holds getters and init functions)
  @param _implementation: The file implementing the registry's functionality
  @return exec_id: The execution id under which the registry will store data
  */
  function createRegistryInstance(address _index, address _implementation) external onlyAdmin() returns (bytes32 exec_id) {
    // Validate input -
    require(_index != 0 && _implementation != 0, 'Invalid input');

    // Creates a registry from storage and returns the registry exec id -
    exec_id = StorageInterface(app_storage).createRegistry(_index, _implementation);

    // Ensure a valid execution id returned from storage -
    require(exec_id != 0, 'Invalid response from storage');

    // If there is not already a default registry exec id set, set it
    if (registry_exec_id == 0)
      registry_exec_id = exec_id;

    // Create Registry struct in memory -
    Registry memory reg = Registry(_index, _implementation);

    // Set various app metadata values -
    deployed_by[exec_id] = msg.sender;
    registry_instance_info[exec_id] = reg;
    deployed_registry_instances[msg.sender].push(reg);
    // Emit event -
    emit RegistryInstanceCreated(msg.sender, exec_id, _index, _implementation);
  }

  /*
  Registers an application as the admin under the provider and registry exec id
  @param _app_name: The name of the application to register
  @param _index: The index file of the application - holds the getters and init functions
  @param _selectors: The selectors of the functions which the app implements
  @param _implementations: The addresses at which each function is located
  */
  function registerApp(bytes32 _app_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
    // Validate input
    require(_app_name != 0 && _index != 0, 'Invalid input');
    require(_selectors.length == _implementations.length && _selectors.length != 0, 'Invalid input');
    // Check contract variables for valid initialization
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, 'Invalid state');

    // Execute registerApp through AbstractStorage -
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

    // Ensure zero values for emitted and paid, and nonzero value for stored -
    require(emitted == 0 && paid == 0 && stored != 0, 'Invalid state change');
  }

  /*
  Registers a version of an application as the admin under the provider and registry exec id
  @param _app_name: The name of the application under which the version will be registered
  @param _version_name: The name of the version to register
  @param _index: The index file of the application - holds the getters and init functions
  @param _selectors: The selectors of the functions which the app implements
  @param _implementations: The addresses at which each function is located
  */
  function registerAppVersion(bytes32 _app_name, bytes32 _version_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
    // Validate input
    require(_app_name != 0 && _version_name != 0 && _index != 0, 'Invalid input');
    require(_selectors.length == _implementations.length && _selectors.length != 0, 'Invalid input');
    // Check contract variables for valid initialization
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, 'Invalid state');

    // Execute registerApp through AbstractStorage -
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

    // Ensure zero values for emitted and paid, and nonzero value for stored -
    require(emitted == 0 && paid == 0 && stored != 0, 'Invalid state change');
  }
}

// File: tmp/ArrayUtils.sol

library ArrayUtils {

  function toBytes4Arr(bytes32[] memory _arr) internal pure returns (bytes4[] memory _conv) {
    assembly { _conv := _arr }
  }

  function toAddressArr(bytes32[] memory _arr) internal pure returns (address[] memory _conv) {
    assembly { _conv := _arr }
  }
}

// File: tmp/GetterInterface.sol

interface GetterInterface {
  function read(bytes32 exec_id, bytes32 location) external view returns (bytes32 data);
  function readMulti(bytes32 exec_id, bytes32[] locations) external view returns (bytes32[] data);
}

// File: tmp/RegistryIdx.sol

library RegistryIdx {

  using Contract for *;
  using ArrayUtils for bytes32[];

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');

  // Returns the storage location of a script execution address's permissions -
  function execPermissions(address _exec) internal pure returns (bytes32 location) {
    location = keccak256(_exec, EXEC_PERMISSIONS);
  }

  // Simple init function - sets the sender as a script executor for this instance
  function init() external view {
    // Begin execution - we are initializing an instance of this application
    Contract.initialize();
    // Begin storing init information -
    Contract.storing();
    // Authorize sender as an executor for this instance -
    Contract.set(execPermissions(msg.sender)).to(true);
    // Finish storing and commit authorized sender to storage -
    Contract.commit();
  }

  // Returns the location of a provider's list of registered applications in storage
  function registeredApps(address _provider) internal pure returns (bytes32 location) {
    location = keccak256(bytes32(_provider), 'app_list');
  }

  // Returns the location of a registered app's name under a provider
  function appBase(bytes32 _app, address _provider) internal pure returns (bytes32 location) {
    location = keccak256(_app, keccak256(bytes32(_provider), 'app_base'));
  }

  // Returns the location of an app's list of versions
  function appVersionList(bytes32 _app, address _provider) internal pure returns (bytes32 location) {
    location = keccak256('versions', appBase(_app, _provider));
  }

  // Returns the location of a version's name
  function versionBase(bytes32 _app, bytes32 _version, address _provider) internal pure returns (bytes32 location) {
    location = keccak256(_version, 'version', appBase(_app, _provider));
  }

  // Returns the location of a registered app's index address under a provider
  function versionIndex(bytes32 _app, bytes32 _version, address _provider) internal pure returns (bytes32 location) {
    location = keccak256('index', versionBase(_app, _version, _provider));
  }

  // Returns the location of an app's function selectors, registered under a provider
  function versionSelectors(bytes32 _app, bytes32 _version, address _provider) internal pure returns (bytes32 location) {
    location = keccak256('selectors', versionBase(_app, _version, _provider));
  }

  // Returns the location of an app's implementing addresses, registered under a provider
  function versionAddresses(bytes32 _app, bytes32 _version, address _provider) internal pure returns (bytes32 location) {
    location = keccak256('addresses', versionBase(_app, _version, _provider));
  }

  // Return a list of applications registered by the address given
  function getApplications(address _storage, bytes32 _exec_id, address _provider) external view returns (bytes32[] memory) {
    uint seed = uint(registeredApps(_provider));

    GetterInterface target = GetterInterface(_storage);
    uint length = uint(target.read(_exec_id, bytes32(seed)));

    bytes32[] memory arr_indices = new bytes32[](length);
    for (uint i = 1; i <= length; i++)
      arr_indices[i - 1] = bytes32((32 * i) + seed);

    return target.readMulti(_exec_id, arr_indices);
  }

  // Return a list of versions of an app registered by the maker
  function getVersions(address _storage, bytes32 _exec_id, address _provider, bytes32 _app) external view returns (bytes32[] memory) {
    uint seed = uint(appVersionList(_app, _provider));

    GetterInterface target = GetterInterface(_storage);
    uint length = uint(target.read(_exec_id, bytes32(seed)));

    bytes32[] memory arr_indices = new bytes32[](length);
    for (uint i = 1; i <= length; i++)
      arr_indices[i - 1] = bytes32((32 * i) + seed);

    return target.readMulti(_exec_id, arr_indices);
  }

  // Returns the latest version of an application
  function getLatestVersion(address _storage, bytes32 _exec_id, address _provider, bytes32 _app) external view returns (bytes32) {
    uint seed = uint(appVersionList(_app, _provider));

    GetterInterface target = GetterInterface(_storage);
    uint length = uint(target.read(_exec_id, bytes32(seed)));

    seed = (32 * length) + seed;

    return target.read(_exec_id, bytes32(seed));
  }

  // Returns a version's index address, function selectors, and implementing addresses
  function getVersionImplementation(address _storage, bytes32 _exec_id, address _provider, bytes32 _app, bytes32 _version) external view
  returns (address index, bytes4[] memory selectors, address[] memory implementations) {
    uint seed = uint(versionIndex(_app, _version, _provider));

    GetterInterface target = GetterInterface(_storage);
    index = address(target.read(_exec_id, bytes32(seed)));

    seed = uint(versionSelectors(_app, _version, _provider));
    uint length = uint(target.read(_exec_id, bytes32(seed)));

    bytes32[] memory arr_indices = new bytes32[](length);
    for (uint i = 1; i <= length; i++)
      arr_indices[i - 1] = bytes32((32 * i) + seed);

    selectors = target.readMulti(_exec_id, arr_indices).toBytes4Arr();

    seed = uint(versionAddresses(_app, _version, _provider));
    for (i = 1; i <= length; i++)
      arr_indices[i - 1] = bytes32((32 * i) + seed);

    implementations = target.readMulti(_exec_id, arr_indices).toAddressArr();
  }
}
