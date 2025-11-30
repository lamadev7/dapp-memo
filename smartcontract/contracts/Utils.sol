// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

// import "./SafeMath.sol";
import "./Constants.sol";

contract Utils is Constants {
    // using SafeMath for uint;

    // Counter variables for gender-based voter statistics
    uint public totalMaleVoters = 0;
    uint public totalFemaleVoters = 0;
    uint public totalOtherVoters = 0;

    /**
     * @dev Updates the gender-based voter counters based on the provided gender
     * @param _gender The gender string to check and update counter for
     */
    function updateCounter(string memory _gender) public {
        if(keccak256(bytes(_gender)) == keccak256(bytes(gender_list[0]))){
            totalMaleVoters++;
        }else if(keccak256(bytes(_gender)) == keccak256(bytes(gender_list[1]))){
            totalFemaleVoters++;
        }else if(keccak256(bytes(_gender)) == keccak256(bytes(gender_list[2]))){
            totalOtherVoters++;
        }
    }
}