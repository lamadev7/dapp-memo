// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Auth is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ELECTION_OFFICER_ROLE = keccak256("ELECTION_OFFICER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    
    address public adminAddress;
    
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event RoleGrantedToUser(address indexed user, bytes32 indexed role);
    
    constructor() {
        adminAddress = msg.sender;
        
        // ✅ CRITICAL: Grant DEFAULT_ADMIN_ROLE first
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        // ✅ Set up role hierarchy (who can grant what)
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ELECTION_OFFICER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VOTER_ROLE, ADMIN_ROLE);
        
        // ✅ Now grant ADMIN_ROLE
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function isAdmin(address _account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _account);
    }
    
    function isElectionOfficer(address _account) public view returns (bool) {
        return hasRole(ELECTION_OFFICER_ROLE, _account);
    }
    
    function isVoter(address _account) public view returns (bool) {
        return hasRole(VOTER_ROLE, _account);
    }
    
    function transferAdmin(address _newAdmin) public onlyRole(ADMIN_ROLE) {
        require(_newAdmin != address(0), "Invalid address");
        require(_newAdmin != adminAddress, "Already admin");
        
        _grantRole(ADMIN_ROLE, _newAdmin);
        _revokeRole(ADMIN_ROLE, adminAddress);
        
        emit AdminChanged(adminAddress, _newAdmin);
        adminAddress = _newAdmin;
    }
    
    function addElectionOfficer(address _officer) public onlyRole(ADMIN_ROLE) {
        require(_officer != address(0), "Invalid address");
        _grantRole(ELECTION_OFFICER_ROLE, _officer);
        emit RoleGrantedToUser(_officer, ELECTION_OFFICER_ROLE);
    }
    
    function registerVoterRole(address _voter) public onlyRole(ADMIN_ROLE) {
        require(_voter != address(0), "Invalid address");
        _grantRole(VOTER_ROLE, _voter);
        emit RoleGrantedToUser(_voter, VOTER_ROLE);
    }
}