// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BridgeableCoin.sol";

contract BridgeOracle is Ownable {
    mapping(uint256 => address) public chainToBridgeableCoin;

    event BridgeRequestSigned(address indexed from, address indexed to, uint256 amount, uint256 sourceChainId, uint256 targetChainId, bytes signature);

    function setBridgeableCoin(uint256 chainId, address coinAddress) external onlyOwner {
        chainToBridgeableCoin[chainId] = coinAddress;
    }

    function signBridgeRequest(address from, address to, uint256 amount, uint256 sourceChainId, uint256 targetChainId) external onlyOwner {
        require(chainToBridgeableCoin[sourceChainId] != address(0), "Source chain not supported");
        require(chainToBridgeableCoin[targetChainId] != address(0), "Target chain not supported");

        bytes32 messageHash = keccak256(abi.encodePacked(to, amount, sourceChainId));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner(), ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        emit BridgeRequestSigned(from, to, amount, sourceChainId, targetChainId, signature);
    }
}