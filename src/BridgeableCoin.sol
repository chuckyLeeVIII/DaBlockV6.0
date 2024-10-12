// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
The BridgeableCoin contract is a crucial component of the FamilyCryptoSystem, enabling cross-chain functionality. It allows the family cryptocurrency to be transferred between different blockchain networks, enhancing the ecosystem's interoperability. Here's an overview of its key features:

1. ERC20 Compatibility: The contract inherits from OpenZeppelin's ERC20 implementation, ensuring it follows standard token practices.

2. Bridge Functionality: It includes functions to initiate and complete bridge requests, allowing tokens to be "transferred" between chains.

3. Security Measures:
   - A lock time between bridge requests prevents rapid, potentially malicious bridging attempts.
   - Signature verification ensures that only authorized bridge completions are processed.

4. Request Tracking: The contract keeps track of processed bridge requests to prevent double-spending across chains.

5. Event Emission: Events are emitted for both initiating and completing bridge requests, allowing for off-chain tracking and synchronization.

This contract plays a vital role in expanding the reach of the family cryptocurrency beyond a single blockchain, potentially allowing families to interact with various DeFi ecosystems across different networks.
*/

contract BridgeableCoin is ERC20, Ownable {
    using ECDSA for bytes32;

    // Constant for the lock time between bridge requests
    uint256 public constant BRIDGE_LOCK_TIME = 24 hours;

    // Mapping to track processed bridge requests
    mapping(bytes32 => bool) public processedBridgeRequests;

    // Mapping to track the last bridge request time for each address
    mapping(address => uint256) public lastBridgeRequestTime;

    // Events
    event BridgeRequestInitiated(address indexed from, uint256 amount, uint256 targetChainId);
    event BridgeRequestCompleted(address indexed to, uint256 amount, uint256 sourceChainId);

    // Constructor to initialize the token with a name and symbol
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Function to mint new tokens (only callable by owner)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Function to initiate a bridge request
    function initiateBridgeRequest(uint256 amount, uint256 targetChainId) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(block.timestamp > lastBridgeRequestTime[msg.sender] + BRIDGE_LOCK_TIME, "Bridge request too soon");

        _burn(msg.sender, amount);
        lastBridgeRequestTime[msg.sender] = block.timestamp;

        emit BridgeRequestInitiated(msg.sender, amount, targetChainId);
    }

    // Function to complete a bridge request (only callable by owner)
    function completeBridgeRequest(address to, uint256 amount, uint256 sourceChainId, bytes memory signature) external onlyOwner {
        bytes32 messageHash = keccak256(abi.encodePacked(to, amount, sourceChainId));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);

        require(signer == owner(), "Invalid signature");
        require(!processedBridgeRequests[messageHash], "Bridge request already processed");

        processedBridgeRequests[messageHash] = true;
        _mint(to, amount);

        emit BridgeRequestCompleted(to, amount, sourceChainId);
    }
}