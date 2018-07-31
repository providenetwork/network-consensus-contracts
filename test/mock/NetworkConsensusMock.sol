pragma solidity ^0.4.21;

import '../../contracts/NetworkConsensus.sol';


contract NetworkConsensusMock is NetworkConsensus {

    constructor(
        address _master_of_ceremony,
        address _abstract_storage,
        address _registry_idx,
        address _registry_impl,
        address _consensus_idx,
        address _validator_console,
        address _voting_console
    ) NetworkConsensus(_master_of_ceremony, _abstract_storage, _registry_idx, _registry_impl, _consensus_idx, _validator_console, _voting_console) public
    {}

    function getRegistryExecId() public view returns (bytes32) {
        return registry_exec_id;
    }

    function getConsensusAppExecId() public view returns (bytes32) {
        return app_exec_id;
    }
}
