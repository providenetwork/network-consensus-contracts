pragma solidity ^0.4.23;

import '../../auth_os.sol';

library VotingConsole {
  using Exceptions for bytes32;
  using LibEvents for uint;
  using LibPayments for uint;
  using LibStorage for uint;
  using MemoryBuffers for uint;
  using Pointers for *; 

  bytes32 internal constant CANDIDATES = keccak256("candidates");
  bytes32 internal constant CANDIDATE_COUNT = keccak256("candidate_count");
  bytes32 internal constant CREATOR = keccak256("creator");
  bytes32 internal constant DATA = keccak256("data");
  bytes32 internal constant FINALIZED = keccak256("finalized");
  bytes32 internal constant PROPOSAL = keccak256("proposal");
  bytes32 internal constant PROPOSALS = keccak256("proposals");
  bytes32 internal constant PROPOSALS_COUNT = keccak256("proposals_count");
  bytes32 internal constant PROPOSED_CALLDATA = keccak256("proposed_calldata");
  bytes32 internal constant PROPOSED_TARGET = keccak256("proposed_target");
  bytes32 internal constant START_TIMESTAMP = keccak256("start_timestamp");
  bytes32 internal constant EXPIRY_TIMESTAMP = keccak256("expiry_timestamp");
  bytes32 internal constant STATUS = keccak256("status");
  bytes32 internal constant TITLE = keccak256("title");
  bytes32 internal constant VOTE = keccak256("vote");
  bytes32 internal constant VOTE_COUNT = keccak256("vote_count");
  bytes32 internal constant VOTED = keccak256("voted");
  bytes32 internal constant VOTES = keccak256("votes");

  bytes4 internal constant GET_PROPOSAL_EXPIRED_SEL = bytes4(keccak256("getProposalExpired(address,bytes32,bytes32)"));
  bytes4 internal constant GET_PROPOSAL_FINALIZED_SEL = bytes4(keccak256("getProposalIsFinalized(address,bytes32,bytes32)"));
  bytes4 internal constant GET_PROPOSAL_STATUS_SEL = bytes4(keccak256("getProposalStatus(address,bytes32,bytes32)"));
  bytes4 internal constant GET_PROPOSAL_CANDIDATE_VOTECOUNT_SEL = bytes4(keccak256("getProposalCandidateVoteCount(address,bytes32,bytes32,bytes32)"));
  bytes4 internal constant GET_PROPOSAL_VOTECOUNT_SEL = bytes4(keccak256("getProposalVoteCount(address,bytes32,bytes32)"));

  bytes4 internal constant GET_PROPOSALS_COUNT_SEL = bytes4(keccak256("getProposalsCount(address,bytes32)"));

  bytes4 internal constant RD_SING = bytes4(keccak256("read(bytes32,bytes32)"));
  bytes4 internal constant RD_MULTI = bytes4(keccak256("readMulti(bytes32,bytes32[])"));

  enum ProposalStatus { Pending, Passed, Expired, Failed }

  /*
  Add a proposal for voting.
  @param _index: The index of the new proposal
  @param _creator: The address creating the new proposal
  @param _nonce: The proposal nonce-- enforced per creator
  @param _start_timestamp: The starting unix timestamp, at which point the proposal is open for voting
  @param _expiry_timestamp: The expiry unix timestamp, at which point the proposal will expire and deemed failed
  @param _title: The title of the proposal
  @param _data: Arbitrary data to attach to the proposal (i.e., may include description, url, etc.)
  @param _candidates: Array of valid values with which a vote can support
  @return store_data: A formatted storage request
  */
  function addProposal(
    uint _index,
    address _creator,
    uint _nonce,
    uint _start_timestamp,
    uint _expiry_timestamp,
    bytes memory _title,
    bytes memory _data,
    bytes32[] memory _candidates
  ) public view returns (bytes memory store_data) {
    bytes32 _proposal_id = keccak256(_creator, keccak256(_title, _nonce));
    uint ptr = buildProposal(_proposal_id, _creator, _start_timestamp, _expiry_timestamp, _title, _data, _candidates);

    ptr.store(keccak256(PROPOSALS_COUNT, _index + 1));

    store_data = ptr.getBuffer();
  }

  /*
  Add an arbitrary proposal for voting. The proposal is arbitrary in that it is created with
  arbitrary calldata and a target, which is executed if the proposal passes voting. Use this
  method to create a proposal that will result in a contract execution if the vote passes.
  @param _index: The index of the new proposal
  @param _creator: The address creating the new proposal
  @param _proposed_target: The proposed target address to which the proposed calldata will be dispatched upon successful vote
  @param _nonce: The proposal nonce-- enforced per creator
  @param _start_timestamp: The starting unix timestamp, at which point the proposal is open for voting
  @param _expiry_timestamp: The expiry unix timestamp, at which point the proposal will expire and deemed failed
  @param _title: The title of the proposal
  @param _data: Arbitrary data to attach to the proposal (i.e., may include description, url, etc.)
  @param _proposed_calldata: The proposed calldata to sent to the proposed target upon successful vote
  @return store_data: A formatted storage request
  */
  function addArbitraryProposal(
    uint _index,
    address _creator,
    address _proposed_target,
    uint _nonce,
    uint _start_timestamp,
    uint _expiry_timestamp,
    bytes memory _title,
    bytes memory _data,
    bytes memory _proposed_calldata
  ) public view returns (bytes memory store_data) {
    bytes32 _proposal_id = keccak256(_creator, keccak256(_title, _nonce));

    bytes32[] memory _candidates = new bytes32[](2);  // binary option
    _candidates[0] = bytes32(0);
    _candidates[1] = bytes32(1);

    uint ptr = buildProposal(_proposal_id, _creator, _start_timestamp, _expiry_timestamp, _title, _data, _candidates);

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), PROPOSED_TARGET));
    ptr.store(bytes32(_proposed_target));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), PROPOSED_CALLDATA));
    ptr.storeBytesAt(_proposed_calldata, keccak256(keccak256(_proposal_id, PROPOSAL), PROPOSED_CALLDATA));

    ptr.store(keccak256(PROPOSALS_COUNT, _index + 1));

    store_data = ptr.getBuffer();
  }

  /*
  Vote on a proposal.
  @param _aura: The address of the application where the voting console getters are exposed
  @param _storage: The application storage address
  @param _exec_id: The exec_id of the application
  @param _proposal_id: The proposal id
  @param _voter: The address casting the vote
  @param _vote: The value representing the validator's vote; must exactly match one of the candidates or be bool in the case of an arbitrary vote
  @return store_data: A formatted storage request
  */
  function vote(
    address _aura,
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id,
    address _voter,
    bytes32 _vote
  ) public view returns (bytes memory store_data) {
    require(_aura != address(0) && _storage != address(0) && _exec_id != bytes32(0));
    require(_proposal_id != bytes32(0) && _voter != address(0));

    bytes memory _proposal_finalized_calldata = abi.encodeWithSelector(GET_PROPOSAL_VOTECOUNT_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _storage, add(0x20, _proposal_finalized_calldata), mload(_proposal_finalized_calldata), 0, 0)
      if gt(success, 0) {
        let _finalized := mload(0x40)
        returndatacopy(_finalized, 0x0, 0x20)
        if gt(_finalized, 0x0) { revert(0, 0) }
      }
    }

    uint _proposal_vote_count = 0;
    bytes memory _proposal_votecount_calldata = abi.encodeWithSelector(GET_PROPOSAL_VOTECOUNT_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _storage, add(0x20, _proposal_votecount_calldata), mload(_proposal_votecount_calldata), 0, 0)
      if gt(success, 0) {
        returndatacopy(_proposal_vote_count, 0x0, 0x20)
      }
    }

    uint _candidate_vote_count = 0;
    bytes memory _candidate_votecount_calldata = abi.encodeWithSelector(GET_PROPOSAL_CANDIDATE_VOTECOUNT_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _storage, add(0x20, _candidate_votecount_calldata), mload(_candidate_votecount_calldata), 0, 0)
      if gt(success, 0) {
        returndatacopy(_candidate_vote_count, 0x0, 0x20)
      }
    }
  
    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), keccak256(_voter, VOTED)));
    ptr.store(bytes32(1));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), keccak256(_voter, VOTE)));
    ptr.store(_vote);

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), VOTE_COUNT));
    ptr.store(bytes32(_proposal_vote_count + 1));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), keccak256(_vote, VOTE_COUNT)));
    ptr.store(bytes32(_candidate_vote_count + 1));

    // emit Vote(_id, _choice, msg.sender, getTime());

    store_data = ptr.getBuffer();
  }

  /*
  Finalize on a proposal.
  @param _aura: The address of the application where the voting console getters are exposed
  @param _storage: The application storage address
  @param _exec_id: The exec_id of the application
  @param _proposal_id: The proposal id
  @return store_data: A formatted storage request
  */
  function finalize(
    address _aura,
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) public view returns (bytes memory store_data) {
    require(_aura != address(0) && _storage != address(0) && _exec_id != bytes32(0));
    require(_proposal_id != bytes32(0));

    uint8 _final_proposal_status = requireNonFinalizedProposalStatus(_aura, _storage, _exec_id, _proposal_id);
    require(_final_proposal_status == uint8(ProposalStatus.Pending));

    bytes32 _is_expired = bytes32(0);
    bytes memory _proposal_is_expired_calldata = abi.encodeWithSelector(GET_PROPOSAL_EXPIRED_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _storage, add(0x20, _proposal_is_expired_calldata), mload(_proposal_is_expired_calldata), 0, 0)
      if gt(success, 0) {
        returndatacopy(_is_expired, 0x0, 0x20)
      }
    }

    if (_is_expired == bytes32(1)) {
      _final_proposal_status = uint8(ProposalStatus.Expired);
    } else {
      uint _proposal_vote_count = 0;
      bytes memory _proposal_votecount_calldata = abi.encodeWithSelector(GET_PROPOSAL_VOTECOUNT_SEL, _storage, _exec_id, _proposal_id);
      assembly {
        let success := staticcall(gas, _storage, add(0x20, _proposal_votecount_calldata), mload(_proposal_votecount_calldata), 0, 0)
        if gt(success, 0) {
          returndatacopy(_proposal_vote_count, 0x0, 0x20)
        }
      }

      uint _candidate_vote_count = 0;
      bytes memory _candidate_votecount_calldata = abi.encodeWithSelector(GET_PROPOSAL_CANDIDATE_VOTECOUNT_SEL, _storage, _exec_id, _proposal_id);
      assembly {
        let success := staticcall(gas, _storage, add(0x20, _candidate_votecount_calldata), mload(_candidate_votecount_calldata), 0, 0)
        if gt(success, 0) {
          returndatacopy(_candidate_vote_count, 0x0, 0x20)
        }
      }

      // TODO: determine if proposal requires simple or supermajority and calculate outcome
    }

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), STATUS));
    ptr.store(bytes32(_final_proposal_status));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), FINALIZED));
    ptr.store(bytes32(1));

    // emit ProposalFinalized(_proposal_id, getTime());

    store_data = ptr.getBuffer();
  }

  function buildProposal(
    bytes32 _proposal_id,
    address _creator,
    uint _start_timestamp,
    uint _expiry_timestamp,
    bytes memory _title,
    bytes memory _data,
    bytes32[] memory _candidates
  ) private pure returns (uint) {
    require(_proposal_id != bytes32(0) && _creator != address(0) && _candidates.length > 1 && _start_timestamp < _expiry_timestamp);

    uint ptr;
    ptr = ptr.clear();
    ptr.stores();
  
    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), CREATOR));
    ptr.store(bytes32(_creator));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), STATUS));
    ptr.store(bytes32(uint8(ProposalStatus.Pending)));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), FINALIZED));
    ptr.store(bytes32(0));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), VOTE_COUNT));
    ptr.store(bytes32(0));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), START_TIMESTAMP));
    ptr.store(bytes32(_start_timestamp));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), EXPIRY_TIMESTAMP));
    ptr.store(bytes32(_expiry_timestamp));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), TITLE));
    ptr.storeBytesAt(_title, keccak256(keccak256(_proposal_id, PROPOSAL), TITLE));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), DATA));
    ptr.storeBytesAt(_data, keccak256(keccak256(_proposal_id, PROPOSAL), DATA));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), CANDIDATE_COUNT));
    ptr.store(bytes32(_candidates.length));

    ptr.store(keccak256(keccak256(_proposal_id, PROPOSAL), CANDIDATES));
    ptr.store(bytes32(_candidates.length));
    for (uint i = 0; i < _candidates.length; i++) {
      ptr.store(bytes32((32 * (i + 1)) + uint(keccak256(keccak256(_proposal_id, PROPOSAL), CANDIDATES))));
      ptr.store(bytes32(_candidates[i]));
    }

    return ptr;
  }

  function requireNonFinalizedProposalStatus(
    address _aura,
    address _storage,
    bytes32 _exec_id,
    bytes32 _proposal_id
  ) private view returns (uint8) {
    bytes memory _proposal_finalized_calldata = abi.encodeWithSelector(GET_PROPOSAL_FINALIZED_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _aura, add(0x20, _proposal_finalized_calldata), mload(_proposal_finalized_calldata), 0, 0)
      if gt(success, 0) {
        let _finalized := mload(0x40)
        returndatacopy(_finalized, 0x0, 0x20)
        if gt(_finalized, 0x0) { revert(0, 0) }
      }
    }

    bytes32 _proposal_status = bytes32(0);
    bytes memory _proposal_status_calldata = abi.encodeWithSelector(GET_PROPOSAL_STATUS_SEL, _storage, _exec_id, _proposal_id);
    assembly {
      let success := staticcall(gas, _aura, add(0x20, _proposal_status_calldata), mload(_proposal_status_calldata), 0, 0)
      if gt(success, 0) {
        returndatacopy(_proposal_status, 0x0, 0x20)
      }
    }
    return uint8(_proposal_status);
  }
}
