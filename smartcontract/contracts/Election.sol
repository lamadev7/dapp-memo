// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Structure.sol";
import "./Auth.sol";
// ✅ Import contracts but DON'T inherit from them
import "./Candidate.sol";
import "./Voter.sol";
import "./Party.sol";

/**
 * @title ElectionManager
 * @notice Main contract - uses COMPOSITION not inheritance
 * ✅ Does NOT inherit from Candidate, Voter, or Party
 */
contract ElectionManager is Structure, Auth, ReentrancyGuard, Pausable {
    
    // ✅ Use composition - store references to other contracts
    Candidate public candidateContract;
    Voter public voterContract;
    Party public partyContract;
    
    mapping(bytes32 => ElectionData) public elections;
    mapping(bytes32 => FAQData) public faqs;
    mapping(bytes32 => mapping(address => bool)) public hasVotedInElection;
    mapping(bytes32 => mapping(address => uint256)) public candidateVotesInElection;
    
    bytes32[] public electionIds;
    bytes32[] public faqIds;
    
    uint256 public totalElections;
    uint256 public totalVotes;
    
    event ElectionCreated(bytes32 indexed electionId, string title, uint256 startTime, uint256 endTime);
    event CandidateAddedToElection(bytes32 indexed electionId, address indexed candidateId);
    event VoteCast(address indexed voter, address indexed candidate, bytes32 indexed electionId, uint256 timestamp);
    event ElectionStatusChanged(bytes32 indexed electionId, ElectionStatus newStatus);
    event FAQCreated(bytes32 indexed faqId, address indexed author);
    event FAQCommentAdded(bytes32 indexed faqId, address indexed commenter);
    
    modifier electionExists(bytes32 _electionId) {
        require(elections[_electionId].id != bytes32(0), "Election not found");
        _;
    }
    
    modifier electionIsActive(bytes32 _electionId) {
        require(elections[_electionId].isActive, "Election not active");
        require(elections[_electionId].status == ElectionStatus.ACTIVE, "Election not in active status");
        require(block.timestamp >= elections[_electionId].startTime, "Election not started");
        require(block.timestamp <= elections[_electionId].endTime, "Election ended");
        _;
    }
    
    /**
     * @notice Constructor - set up references to other contracts
     * ✅ Takes contract addresses as parameters
     */
    constructor(
        address _candidateContract,
        address _voterContract,
        address _partyContract
    ) {
        require(_candidateContract != address(0), "Invalid candidate contract");
        require(_voterContract != address(0), "Invalid voter contract");
        require(_partyContract != address(0), "Invalid party contract");
        
        candidateContract = Candidate(_candidateContract);
        voterContract = Voter(_voterContract);
        partyContract = Party(_partyContract);
    }
    
    function createElection(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        ElectionType _electionType,
        string[] memory _galleryUrls,
        address[] memory _candidateAddresses,
        string memory _boothPlace,
        string memory _position
    ) public onlyRole(ADMIN_ROLE) returns (bytes32) {
        require(bytes(_title).length > 0, "Title required");
        require(_startTime > block.timestamp, "Start time must be in future");
        require(_endTime > _startTime, "End time must be after start");
        
        bytes32 electionId = keccak256(abi.encodePacked(_title, _startTime, block.timestamp, msg.sender));
        require(elections[electionId].id == bytes32(0), "Election ID collision");
        
        ElectionData storage election = elections[electionId];
        election.id = electionId;
        election.title = _title;
        election.description = _description;
        election.startTime = _startTime;
        election.endTime = _endTime;
        election.electionType = _electionType;
        election.galleryUrls = _galleryUrls;
        election.isActive = true;
        election.status = ElectionStatus.PENDING;
        election.totalVotes = 0;
        election.candidateAddresses = _candidateAddresses;
        election.boothPlace = _boothPlace;
        election.position = _position;
        electionIds.push(electionId);
        totalElections++;
        
        emit ElectionCreated(electionId, _title, _startTime, _endTime);
        return electionId;
    }
    
    function addCandidatesToElection(
        bytes32 _electionId,
        address[] memory _candidateAddresses
    ) public onlyRole(ADMIN_ROLE) electionExists(_electionId) {
        require(block.timestamp < elections[_electionId].startTime, "Cannot add candidates after election starts");
        require(_candidateAddresses.length > 0, "No candidates provided");
        
        for (uint256 i = 0; i < _candidateAddresses.length; i++) {
            address candidateAddr = _candidateAddresses[i];
            require(candidateAddr != address(0), "Invalid candidate address");
            require(candidateContract.isCandidate(candidateAddr), "Not a registered candidate");
            
            elections[_electionId].candidateAddresses.push(candidateAddr);
            emit CandidateAddedToElection(_electionId, candidateAddr);
        }
    }
    
    function startElection(bytes32 _electionId) public onlyRole(ADMIN_ROLE) electionExists(_electionId) {
        require(elections[_electionId].status == ElectionStatus.PENDING, "Election not pending");
        require(elections[_electionId].candidateAddresses.length >= 2, "Need at least 2 candidates");
        require(block.timestamp >= elections[_electionId].startTime, "Election start time not reached");
        
        elections[_electionId].status = ElectionStatus.ACTIVE;
        emit ElectionStatusChanged(_electionId, ElectionStatus.ACTIVE);
    }
    
    function vote(
        bytes32 _electionId,
        address _candidateId
    ) public nonReentrant whenNotPaused electionExists(_electionId) {
        address voter = msg.sender;
        
        require(voterContract.isRegisteredVoter(voter), "Not a registered voter");
        require(!candidateContract.isCandidate(voter), "Candidates cannot vote");
        require(!isAdmin(voter), "Admins cannot vote");
        require(_candidateId != address(0), "Invalid candidate");
        require(candidateContract.isCandidate(_candidateId), "Not a registered candidate");
        require(!hasVotedInElection[_electionId][voter], "Already voted in this election");
        
        bool candidateInElection = false;
        for (uint256 i = 0; i < elections[_electionId].candidateAddresses.length; i++) {
            if (elections[_electionId].candidateAddresses[i] == _candidateId) {
                candidateInElection = true;
                break;
            }
        }
        require(candidateInElection, "Candidate not in this election");
        
        hasVotedInElection[_electionId][voter] = true;
        candidateVotesInElection[_electionId][_candidateId]++;
        elections[_electionId].totalVotes++;
        totalVotes++;
        
        candidateContract.incrementVoteCount(_candidateId);
        voterContract.incrementVoteCount(voter);
        
        emit VoteCast(voter, _candidateId, _electionId, block.timestamp);
    }
    
    function endElection(bytes32 _electionId) public onlyRole(ADMIN_ROLE) electionExists(_electionId) {
        require(elections[_electionId].status == ElectionStatus.ACTIVE, "Election not active");
        require(block.timestamp > elections[_electionId].endTime, "Election end time not reached");
        
        elections[_electionId].status = ElectionStatus.COMPLETED;
        elections[_electionId].isActive = false;
        
        emit ElectionStatusChanged(_electionId, ElectionStatus.COMPLETED);
    }
    
    function getElectionResults(bytes32 _electionId) 
        public 
        view 
        electionExists(_electionId) 
        returns (address[] memory, uint256[] memory, uint256) 
    {
        uint256 candidateCount = elections[_electionId].candidateAddresses.length;
        address[] memory candidateAddresses = new address[](candidateCount);
        uint256[] memory votes = new uint256[](candidateCount);
        
        for (uint256 i = 0; i < candidateCount; i++) {
            address candidateAddr = elections[_electionId].candidateAddresses[i];
            candidateAddresses[i] = candidateAddr;
            votes[i] = candidateVotesInElection[_electionId][candidateAddr];
        }
        
        return (candidateAddresses, votes, elections[_electionId].totalVotes);
    }
    
    function getAllElections() public view returns (ElectionData[] memory) {
        ElectionData[] memory allElections = new ElectionData[](electionIds.length);
        for (uint256 i = 0; i < electionIds.length; i++) {
            allElections[i] = elections[electionIds[i]];
        }
        return allElections;
    }
    
    function pause() public onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() public onlyRole(ADMIN_ROLE) { _unpause(); }
}