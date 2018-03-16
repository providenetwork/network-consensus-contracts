pragma solidity ^0.4.20;

import '../../contracts/network/KeyManager.sol';


contract KeyManagerMock is KeyManager {
    function KeyManagerMock(address _networkConsensus, address _prevKeyManager) KeyManager(_networkConsensus, _prevKeyManager) public {}

    function setVotingContractMock(address _votingContract) public {
        networkStorage.setAddress(VOTING_CONTRACT_KEY, _votingContract);
    }

    function setMaxTotalValidators(uint256 maxTotalValidators) public {
        networkStorage.setUint(MAX_TOTAL_VALIDATORS_KEY, maxTotalValidators);
    }

    function setMaxInitialValidators(uint256 maxInitialValidators) public {
        networkStorage.setUint(MAX_INITIAL_VALIDATORS_KEY, maxInitialValidators);
    }

    function unmarshalValidatorKeysMock(address _addr) public view returns(address, address, bool, bool, bool) {
        Keys memory keys = unmarshalValidatorKeys(_addr);
        return (keys.payoutKey, keys.votingKey, keys.isMiningActive, keys.isPayoutActive, keys.isVotingActive);
    }
}
