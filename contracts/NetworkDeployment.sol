pragma solidity ^0.4.23;

import './NetworkConsensus.sol';
import './lib/aura/functions/init/Aura.sol';
import './lib/aura/functions/ValidatorConsole.sol';
import './lib/aura/functions/VotingConsole.sol';

contract NetworkDeployment {
    constructor(address _master_of_ceremony) public {
        address _registry_storage = new RegistryStorage();

        address _init_registry = new InitRegistry();
        address _app_console = new AppConsole();
        address _version_console = new VersionConsole();
        address _impl_console = new ImplementationConsole();

        address _aura = new Aura();
        address _validator_console = new ValidatorConsole();
        address _voting_console = new VotingConsole();
        
        new NetworkConsensus(
            _master_of_ceremony,
            _registry_storage,
            _init_registry,
            _app_console,
            _version_console,
            _impl_console,
            _aura,
            _validator_console,
            _voting_console
        );
    }
}
