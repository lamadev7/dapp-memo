// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Structure.sol";
import "./Auth.sol";

/**
 * @title Party
 * @notice Standalone contract for party management
 * ✅ NO INHERITANCE FROM OTHER BUSINESS LOGIC CONTRACTS
 */
contract Party is Structure, Auth, ReentrancyGuard {
    
    mapping(bytes32 => PartyData) public parties;
    mapping(bytes32 => bool) public partyNameExists;
    
    bytes32[] public partyIds;
    uint256 public totalParties;
    
    event PartyCreated(bytes32 indexed partyId, string name, address indexed owner, uint256 timestamp);
    event PartyUpdated(bytes32 indexed partyId, string field, uint256 timestamp);
    event MemberAdded(bytes32 indexed partyId, address indexed member, uint256 timestamp);
    event PartyDeactivated(bytes32 indexed partyId, uint256 timestamp);
    
    function createParty(
        string memory _name,
        uint256 _totalMembers,
        string memory _agenda,
        string memory _logoUrl
    ) public onlyRole(ADMIN_ROLE) nonReentrant returns (bytes32) {
        require(bytes(_name).length > 0, "Party name required");
        require(bytes(_agenda).length > 0, "Agenda required");
        require(_totalMembers > 0, "Total members must be > 0");
        
        bytes32 partyId = keccak256(abi.encodePacked(_name, block.timestamp));
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        
        require(!partyNameExists[nameHash], "Party name already exists");
        
        PartyData storage party = parties[partyId];
        party.id = partyId;
        party.owner = msg.sender;
        party.name = _name;
        party.totalMembers = _totalMembers;
        party.agenda = _agenda;
        party.logoUrl = _logoUrl;
        party.isActive = true;
        party.registeredAt = block.timestamp;
        
        partyNameExists[nameHash] = true;
        partyIds.push(partyId);
        totalParties++;
        
        emit PartyCreated(partyId, _name, msg.sender, block.timestamp);
        return partyId;
    }
    
    function addMemberToParty(bytes32 _partyId, address _memberAddress) 
        public 
        onlyRole(ADMIN_ROLE) 
    {
        require(parties[_partyId].id != bytes32(0), "Party not found");
        require(_memberAddress != address(0), "Invalid member address");
        require(parties[_partyId].isActive, "Party not active");
        
        parties[_partyId].memberAddresses.push(_memberAddress);
        emit MemberAdded(_partyId, _memberAddress, block.timestamp);
    }
    
    function getAllParties() public view returns (PartyData[] memory) {
        PartyData[] memory allParties = new PartyData[](partyIds.length);
        for (uint256 i = 0; i < partyIds.length; i++) {
            allParties[i] = parties[partyIds[i]];
        }
        return allParties;
    }
    
    function getPartyDetails(bytes32 _partyId) public view returns (PartyData memory) {
        require(parties[_partyId].id != bytes32(0), "Party not found");
        return parties[_partyId];
    }
    
    function partyExists(bytes32 _partyId) public view returns (bool) {
        return parties[_partyId].id != bytes32(0);
    }
}