pragma solidity ^0.4.23;

interface IVotingConsole {

    // function getProposals(
    //     address _storage, 
    //     bytes32 _exec_id
    // ) external view returns (address[] memory);

    // function getProposalsCount(
    //     address _storage, 
    //     bytes32 _exec_id
    // ) external view returns (uint);

    // function getProposalCandidates(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (bytes32[] memory);

    // function getProposalCandidateCount(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint);

    // function getProposalExpired(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (bool);

    // function getProposalIsFinalized(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (bool);

    // function getProposalStatus(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint8);

    // function getProposalStartTimestamp(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint);

    // function getProposalExpiryTimestamp(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint);

    // function getProposalVoteCount(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint);

    // function getProposalCandidateVoteCount(
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id,
    //     bytes32 _candidate
    // ) external view returns (uint);

    // function addProposal(
    //     uint _index,
    //     address _creator,
    //     uint _nonce,
    //     uint _start_timestamp,
    //     uint _expiry_timestamp,
    //     bytes _title,
    //     bytes _data,
    //     bytes32[] _candidates
    // ) external view;

    // function addArbitraryProposal(
    //     uint _index,
    //     address _creator,
    //     address _proposed_target,
    //     uint _nonce,
    //     uint _start_timestamp,
    //     uint _expiry_timestamp,
    //     bytes _title,
    //     bytes _data,
    //     bytes _proposed_calldata
    // ) external view;

    // function vote(
    //     address _aura,
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id,
    //     address _voter,
    //     bytes32 _vote
    // ) external view;

    // function finalize(
    //     address _aura,
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view;

    // function buildProposal(
    //     bytes32 _proposal_id,
    //     address _creator,
    //     uint _start_timestamp,
    //     uint _expiry_timestamp,
    //     bytes _title,
    //     bytes _data,
    //     bytes32[] _candidates
    // ) external view returns (uint);

    // function requireNonFinalizedProposalStatus(
    //     address _aura,
    //     address _storage,
    //     bytes32 _exec_id,
    //     bytes32 _proposal_id
    // ) external view returns (uint8);
}

interface VotingConsoleIdx {

}
