pragma solidity ^0.4.21;

import '../../contracts/NetworkConsensus.sol';


contract NetworkConsensusMock is NetworkConsensus {

    constructor(
        address _master_of_ceremony,
        address _registry_storage,
        address _init_registry,
        address _app_console,
        address _version_console,
        address _impl_console,
        address _consensus_init,
        address _validator_console,
        address _voting_console
    ) NetworkConsensus(_master_of_ceremony, _registry_storage, _init_registry, _app_console, _version_console, _impl_console, _consensus_init, _validator_console, _voting_console) public
    {}

    function getConsensusAppExecId() public view returns (bytes32) {
        return appExecId;
    }

    function getRegistryAddress() public view returns (address) {
        return registry;
    }
    
    function getValidatorConsoleAddress() public view returns (address) {
        return getValidatorConsole();
    }

    function getVotingConsoleAddress() public view returns (address) {
        return getVotingConsole();
    }

    function getAppProviderHash(address _provider) public pure returns (bytes32 provider) {
        provider = keccak256(bytes32(_provider));
    }
}
