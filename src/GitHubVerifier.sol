// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GitHubVerifier is Ownable {
    using ECDSA for bytes32;

    mapping(string => bool) public verifiedAccounts;
    mapping(string => uint256) public accountReputationScore;

    event GitHubAccountVerified(string githubUsername, address userAddress);
    event ReputationScoreUpdated(string githubUsername, uint256 newScore);

    function verifyGitHubAccount(string memory _githubUsername, address _userAddress, bytes memory _signature) external {
        bytes32 messageHash = keccak256(abi.encodePacked(_githubUsername, _userAddress));
        address signer = messageHash.toEthSignedMessageHash().recover(_signature);
        require(signer == owner(), "Invalid signature");

        verifiedAccounts[_githubUsername] = true;
        emit GitHubAccountVerified(_githubUsername, _userAddress);
    }

    function updateReputationScore(string memory _githubUsername, uint256 _newScore) external onlyOwner {
        require(verifiedAccounts[_githubUsername], "GitHub account not verified");
        accountReputationScore[_githubUsername] = _newScore;
        emit ReputationScoreUpdated(_githubUsername, _newScore);
    }

    function getReputationScore(string memory _githubUsername) external view returns (uint256) {
        require(verifiedAccounts[_githubUsername], "GitHub account not verified");
        return accountReputationScore[_githubUsername];
    }
}