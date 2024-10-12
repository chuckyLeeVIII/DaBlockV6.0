// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FamilyCryptoSystem.sol";

contract SecuritySystem is Ownable {
    FamilyCryptoSystem public familyCryptoSystem;

    struct IoTDevice {
        string deviceType;
        uint256 securityScore;
        bool isActive;
    }

    mapping(address => mapping(uint256 => IoTDevice)) public familyIoTDevices;
    mapping(address => uint256) public familyIoTDeviceCount;

    event IoTDeviceRegistered(address indexed family, uint256 deviceId, string deviceType);
    event IoTDeviceDeactivated(address indexed family, uint256 deviceId);

    constructor() {}

    function setFamilyCryptoSystem(address _familyCryptoSystem) external onlyOwner {
        familyCryptoSystem = FamilyCryptoSystem(_familyCryptoSystem);
    }

    function registerIoTDevice(string memory deviceType) external {
        uint256 deviceId = familyIoTDeviceCount[msg.sender];
        uint256 securityScore = calculateDeviceSecurityScore(deviceType);
        
        familyIoTDevices[msg.sender][deviceId] = IoTDevice(deviceType, securityScore, true);
        familyIoTDeviceCount[msg.sender] = deviceId + 1;
        
        updateFamilySecurityScore(msg.sender);
        
        emit IoTDeviceRegistered(msg.sender, deviceId, deviceType);
    }

    function deactivateIoTDevice(uint256 deviceId) external {
        require(familyIoTDevices[msg.sender][deviceId].isActive, "Device is not active");
        
        familyIoTDevices[msg.sender][deviceId].isActive = false;
        
        updateFamilySecurityScore(msg.sender);
        
        emit IoTDeviceDeactivated(msg.sender, deviceId);
    }

    function calculateDeviceSecurityScore(string memory deviceType) internal pure returns (uint256) {
        bytes32 deviceHash = keccak256(abi.encodePacked(deviceType));
        
        if (deviceHash == keccak256(abi.encodePacked("camera"))) {
            return 10;
        } else if (deviceHash == keccak256(abi.encodePacked("doorLock"))) {
            return 15;
        } else if (deviceHash == keccak256(abi.encodePacked("motionSensor"))) {
            return 8;
        } else {
            return 5;
        }
    }

    function updateFamilySecurityScore(address family) internal {
        uint256 totalScore = 0;
        uint256 deviceCount = familyIoTDeviceCount[family];
        
        for (uint256 i = 0; i < deviceCount; i++) {
            if (familyIoTDevices[family][i].isActive) {
                totalScore += familyIoTDevices[family][i].securityScore;
            }
        }
        
        familyCryptoSystem.updateFamilySecurityScore(family, totalScore);
    }
}