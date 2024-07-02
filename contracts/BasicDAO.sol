// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract BasicDAO {
    // Define the Proposal struct with additional fields
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // Enum for the Proposal Status (Note: Not used in this version of the contract)
    enum ProposalStatus {
        Pending,
        Approved,
        Rejected
    }

    // State variables
    uint256 public membershipFee;
    address public owner;
    address[] public members;
    Proposal[] public proposals;
    mapping(address => bool) public isMember;
    // Track votes with a mapping from proposal ID to the address of the member and their vote status
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events
    event MemberJoined(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event Voted(address indexed member, uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Constructor
    constructor(uint256 _membershipFee) {
        membershipFee = _membershipFee;
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAO member");
        _;
    }

    // Join the DAO by paying the membership fee
    function joinDAO() external payable {
        require(msg.value == membershipFee, "Incorrect membership fee");
        require(!isMember[msg.sender], "Already a member");

        isMember[msg.sender] = true;
        members.push(msg.sender);

        emit MemberJoined(msg.sender);
    }

    // Create a new proposal
    function createProposal(string memory _description, uint256 _deadline) external onlyMember {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        proposals.push(Proposal({
            description: _description,
            deadline: _deadline,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        }));

        emit ProposalCreated(proposals.length - 1, _description, _deadline);
    }

    // Vote on a proposal
    function vote(uint256 _proposalId, bool _voteFor) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, _voteFor);
    }

    // Execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Execute the proposal (this can be expanded based on the proposal's nature)
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
        
        proposal.executed = true;
    }


    // Retrieve the list of members
    function getMembers() external view returns (address[] memory) {
        return members;
    }

    // Retrieve all proposals with their essential details
    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    // Retrieve the current membership fee
    function getMembershipFee() external view returns (uint256) {
        return membershipFee;
    }
}
