pragma solidity ^0.4.23;

import './lib/aura/contracts/AuraProxy.sol';

/*
Network consensus.

See https://wiki.parity.io/Aura
*/
contract NetworkConsensus is AuraProxy {

    constructor(
        address _master_of_ceremony,
        address _abstract_storage,
        address _registry_idx,
        address _registry_impl,
        address _consensus_idx,
        address _validator_console,
        address _voting_console
    ) public AuraProxy(_master_of_ceremony, _abstract_storage, _registry_idx, _registry_impl, _consensus_idx, _validator_console, _voting_console) {}
}
