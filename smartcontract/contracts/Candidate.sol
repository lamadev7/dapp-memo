// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Structure.sol";
import "./Auth.sol";

contract Candidate is Structure, Auth, ReentrancyGuard {
    
    mapping(address => CandidateData) public candidates;
    mapping(uint256 => bool) public usedCitizenshipNumbers;
    mapping(bytes32 => bool) public usedEmailHashes;
    
    address[] public candidateAddresses;
    
    uint256 public totalCandidates;
    uint256 public totalMaleCandidates;
    uint256 public totalFemaleCandidates;
    uint256 public totalOtherCandidates;
    
    event CandidateRegistered(address indexed candidateId, string name, string partyName, uint256 timestamp);
    event CandidateUpdated(address indexed candidateId, string field, uint256 timestamp);
    event CandidateDeactivated(address indexed candidateId, uint256 timestamp);
    
    // ✅ Add constructor
    constructor() Auth() {}
    
    function registerCandidate(
        string memory _fullName,
        uint256 _citizenshipNo,
        uint8 _age,
        Gender _gender,
        uint256 _dob,
        string memory _email,
        string memory _profileUrl,
        string memory _province,
        string memory _district,
        string memory _municipality,
        uint8 _ward,
        string memory _partyName,
        string memory _agenda
    ) public nonReentrant {
        address candidateId = msg.sender;
        
        require(!candidates[candidateId].isRegistered, "Already registered");
        require(bytes(_fullName).length > 0, "Name required");
        require(bytes(_email).length > 0, "Email required");
        require(_age >= 25, "Must be 25 or older");
        require(bytes(_partyName).length > 0, "Party name required");
        require(bytes(_agenda).length > 0, "Agenda required");
        require(!usedCitizenshipNumbers[_citizenshipNo], "Citizenship number already registered");
        
        bytes32 emailHash = keccak256(abi.encodePacked(_email));
        require(!usedEmailHashes[emailHash], "Email already registered");
        
        User memory user = User({
            id: candidateId,
            fullName: _fullName,
            citizenshipNumber: _citizenshipNo,
            age: _age,
            gender: _gender,
            dob: _dob,
            email: _email,
            profileUrl: _profileUrl,
            province: _province,
            district: _district,
            municipality: _municipality,
            ward: _ward
        });
        
        CandidateData storage candidate = candidates[candidateId];
        candidate.user = user;
        candidate.partyName = _partyName;
        candidate.agenda = _agenda;
        candidate.isRegistered = true;
        candidate.isActive = true;
        candidate.registeredAt = block.timestamp;
        candidate.totalVotesReceived = 0;
        candidate.position = "";
        
        usedCitizenshipNumbers[_citizenshipNo] = true;
        usedEmailHashes[emailHash] = true;
        candidateAddresses.push(candidateId);
        totalCandidates++;
        
        if (_gender == Gender.MALE) totalMaleCandidates++;
        else if (_gender == Gender.FEMALE) totalFemaleCandidates++;
        else totalOtherCandidates++;
        
        emit CandidateRegistered(candidateId, _fullName, _partyName, block.timestamp);
    }
    
    function updateCandidatePosition(address _candidateId, string memory _position) 
        public 
        onlyRole(ADMIN_ROLE) 
    {
        require(candidates[_candidateId].isRegistered, "Candidate not found");
        require(bytes(_position).length > 0, "Position required");
        candidates[_candidateId].position = _position;
        emit CandidateUpdated(_candidateId, "position", block.timestamp);
    }
    
    function incrementVoteCount(address _candidateId) external onlyRole(ADMIN_ROLE) {
        require(candidates[_candidateId].isRegistered, "Candidate not found");
        require(candidates[_candidateId].isActive, "Candidate not active");
        candidates[_candidateId].totalVotesReceived++;
    }
    
    function deactivateCandidate(address _candidateId) public onlyRole(ADMIN_ROLE) {
        require(candidates[_candidateId].isRegistered, "Candidate not found");
        require(candidates[_candidateId].isActive, "Already deactivated");
        candidates[_candidateId].isActive = false;
        emit CandidateDeactivated(_candidateId, block.timestamp);
    }
    
    function getAllCandidates() public view returns (CandidateData[] memory) {
        CandidateData[] memory allCandidates = new CandidateData[](candidateAddresses.length);
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            allCandidates[i] = candidates[candidateAddresses[i]];
        }
        return allCandidates;
    }
    
    function getCandidateDetails(address _candidateId) public view returns (CandidateData memory) {
        require(candidates[_candidateId].isRegistered, "Candidate not found");
        return candidates[_candidateId];
    }
    
    function isCandidate(address _address) public view returns (bool) {
        return candidates[_address].isRegistered;
    }
    
    function isCandidateActive(address _address) public view returns (bool) {
        return candidates[_address].isRegistered && candidates[_address].isActive;
    }
}