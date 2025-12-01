// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Structure
 * @notice Defines all data structures used across contracts
 */
contract Structure {
    
    struct User {
        address id;
        string fullName;
        uint256 citizenshipNumber;
        uint8 age;
        Gender gender;
        uint256 dob; // Unix timestamp
        string email;
        string profileUrl;
        string province;
        string district;
        string municipality;
        uint8 ward;
    }
    
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    
    struct VoterData {
        User user;
        bool isRegistered;  // ✅ Added
        uint8 votesCount;
        uint256 registeredAt;
    }
    
    struct CandidateData {
        User user;
        string partyName;
        string position;
        string agenda;
        uint256 totalVotesReceived;
        bool isRegistered;  // ✅ Added - this was missing!
        bool isActive;
        uint256 registeredAt;
    }
    
    struct PartyData {
        bytes32 id;  // ✅ Added unique ID
        address owner;
        string name;
        uint256 totalMembers;
        string agenda;
        string logoUrl;
        address[] memberAddresses;
        bool isActive;
        uint256 registeredAt;
    }
    
    struct ElectionData {
        bytes32 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        ElectionType electionType;
        address[] candidateAddresses;
        string[] galleryUrls;
        uint256 totalVotes;
        bool isActive;
        ElectionStatus status;
        string boothPlace;
        string position;
    }
    
    enum ElectionType {
        Local,
        District,
        Province
    }
    
    enum ElectionStatus {
        PENDING,
        ACTIVE,
        COMPLETED,
        CANCELLED
    }
    
    struct FAQData {
        bytes32 id;
        address author;
        string title;
        string description;
        string fileUrl;
        uint256 createdAt;
        ReplyComment[] comments;
    }
    
    struct ReplyComment {
        address userId;
        string message;
        uint256 timestamp;
    }
}