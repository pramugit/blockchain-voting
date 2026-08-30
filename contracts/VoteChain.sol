// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title VoteChain — Decentralized Voting and Governance System
/// @notice Supports multiple independent elections on a single deployed contract.
contract VoteChain {
    address public organiser;
    uint public electionCount;

    struct Election {
        string title;
        string[] options;
        uint startTime;
        uint endTime;
        bool exists;
        mapping(address => bool) isEligible;
        mapping(address => bool) hasVoted;
        mapping(address => uint) choiceOf;   // 1-based; 0 = not voted
        mapping(uint => uint) tally;
    }
    mapping(uint => Election) private elections;

    event ElectionCreated(uint indexed id, string title, uint startTime, uint endTime);
    event VoterRegistered(uint indexed id, address voter);
    event VoteCast(uint indexed id, address indexed voter, uint optionIndex);
    event VoteChanged(uint indexed id, address indexed voter, uint newOptionIndex);

    modifier onlyOrganiser() {
        require(msg.sender == organiser, "not organiser");
        _;
    }
    modifier electionExists(uint id) {
        require(elections[id].exists, "no such election");
        _;
    }
    modifier onlyEligible(uint id) {
        require(elections[id].isEligible[msg.sender], "not eligible");
        _;
    }
    modifier withinPeriod(uint id) {
        require(block.timestamp >= elections[id].startTime, "not open yet");
        require(block.timestamp < elections[id].endTime, "voting closed");
        _;
    }

    constructor() {
        organiser = msg.sender;
    }

    /// @notice Create a new election. Only the organiser may call this.
    function createElection(
        string memory title,
        string[] memory options,
        uint startTime,
        uint endTime
    ) external onlyOrganiser returns (uint id) {
        require(endTime > startTime, "bad window");
        require(options.length >= 2, "need at least 2 options");
        id = electionCount++;
        Election storage e = elections[id];
        e.title = title;
        e.options = options;
        e.startTime = startTime;
        e.endTime = endTime;
        e.exists = true;
        emit ElectionCreated(id, title, startTime, endTime);
    }

    /// @notice Whitelist a voter address for a specific election. Organiser only.
    function registerVoter(uint id, address voter) external onlyOrganiser electionExists(id) {
        elections[id].isEligible[voter] = true;
        emit VoterRegistered(id, voter);
    }

    /// @notice Cast a first-time vote. Reverts if the caller already voted.
    function castVote(uint id, uint optionIndex)
        external
        electionExists(id)
        onlyEligible(id)
        withinPeriod(id)
    {
        Election storage e = elections[id];
        require(!e.hasVoted[msg.sender], "already voted, use changeVote");
        require(optionIndex < e.options.length, "bad option");
        e.hasVoted[msg.sender] = true;
        e.choiceOf[msg.sender] = optionIndex + 1;
        e.tally[optionIndex] += 1;
        emit VoteCast(id, msg.sender, optionIndex);
    }

    /// @notice Change an existing vote before the deadline.
    function changeVote(uint id, uint newOptionIndex)
        external
        electionExists(id)
        onlyEligible(id)
        withinPeriod(id)
    {
        Election storage e = elections[id];
        require(e.hasVoted[msg.sender], "no existing vote");
        require(newOptionIndex < e.options.length, "bad option");
        e.tally[e.choiceOf[msg.sender] - 1] -= 1;
        e.choiceOf[msg.sender] = newOptionIndex + 1;
        e.tally[newOptionIndex] += 1;
        emit VoteChanged(id, msg.sender, newOptionIndex);
    }

    /// @notice Read the live or final tally for an election. Free to call.
    function getResults(uint id)
        external
        view
        electionExists(id)
        returns (string[] memory names, uint[] memory counts)
    {
        Election storage e = elections[id];
        names = e.options;
        counts = new uint[](e.options.length);
        for (uint i = 0; i < e.options.length; i++) {
            counts[i] = e.tally[i];
        }
    }

    /// @notice Convenience getter for the frontend to fetch an election's metadata.
    function getElectionInfo(uint id)
        external
        view
        electionExists(id)
        returns (string memory title, string[] memory options, uint startTime, uint endTime)
    {
        Election storage e = elections[id];
        return (e.title, e.options, e.startTime, e.endTime);
    }

    /// @notice Whether a given address has already voted in a given election.
    function hasVotedIn(uint id, address voter) external view electionExists(id) returns (bool) {
        return elections[id].hasVoted[voter];
    }
}
