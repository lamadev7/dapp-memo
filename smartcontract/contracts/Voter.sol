// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Structure.sol";
import "./Auth.sol";

contract Voter is Structure, Auth, ReentrancyGuard {
    
    mapping(address => VoterData) public voters;
    mapping(uint256 => bool) public usedCitizenshipNumbers;
    mapping(bytes32 => bool) public usedEmailHashes;
    
    address[] public voterAddresses;
    
    uint256 public totalVoters;
    uint256 public totalMaleVoters;
    uint256 public totalFemaleVoters;
    uint256 public totalOtherVoters;
    
    event VoterRegistered(address indexed voterId, string name, uint256 timestamp);
    
    // ✅ Add constructor
    constructor() Auth() {}
    
    function registerVoter(
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
        uint8 _ward
    ) public nonReentrant {
        address voterId = msg.sender;
        
        require(!voters[voterId].isRegistered, "Already registered");
        require(bytes(_fullName).length > 0, "Name required");
        require(bytes(_email).length > 0, "Email required");
        require(_age >= 18, "Must be 18 or older");
        require(!usedCitizenshipNumbers[_citizenshipNo], "Citizenship number already registered");
        
        bytes32 emailHash = keccak256(abi.encodePacked(_email));
        require(!usedEmailHashes[emailHash], "Email already registered");
        
        User memory user = User({
            id: voterId,
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
        
        VoterData storage voter = voters[voterId];
        voter.user = user;
        voter.isRegistered = true;
        voter.votesCount = 0;
        voter.registeredAt = block.timestamp;
        
        usedCitizenshipNumbers[_citizenshipNo] = true;
        usedEmailHashes[emailHash] = true;
        voterAddresses.push(voterId);
        totalVoters++;
        
        if (_gender == Gender.MALE) totalMaleVoters++;
        else if (_gender == Gender.FEMALE) totalFemaleVoters++;
        else totalOtherVoters++;
        
        _grantRole(VOTER_ROLE, voterId);
        
        emit VoterRegistered(voterId, _fullName, block.timestamp);
    }
    
    function incrementVoteCount(address _voterId) external onlyRole(ADMIN_ROLE) {
        require(voters[_voterId].isRegistered, "Voter not found");
        voters[_voterId].votesCount++;
    }
    
    function getAllVoters() public view returns (VoterData[] memory) {
        VoterData[] memory allVoters = new VoterData[](voterAddresses.length);
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            allVoters[i] = voters[voterAddresses[i]];
        }
        return allVoters;
    }
    
    function getVoterDetails(address _voterId) public view returns (VoterData memory) {
        require(voters[_voterId].isRegistered, "Voter not found");
        return voters[_voterId];
    }
    
    function isRegisteredVoter(address _address) public view returns (bool) {
        return voters[_address].isRegistered;
    }
}