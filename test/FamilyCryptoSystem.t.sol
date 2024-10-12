// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FamilyCryptoSystem.sol";
import "../src/MemeToken.sol";

contract FamilyCryptoSystemTest is Test {
    FamilyCryptoSystem public familyCryptoSystem;
    MemeToken public memeToken;
    address public family1;
    address public family2;

    function setUp() public {
        memeToken = new MemeToken("FamilyMeme", "FMEME");
        familyCryptoSystem = new FamilyCryptoSystem(address(memeToken));
        memeToken.setFamilyCryptoSystem(address(familyCryptoSystem));

        family1 = address(0x1);
        family2 = address(0x2);
        vm.startPrank(family1);
        familyCryptoSystem.registerFamily();
        vm.stopPrank();

        vm.startPrank(family2);
        familyCryptoSystem.registerFamily();
        vm.stopPrank();
    }

    function testRegisterFamily() public {
        assertTrue(familyCryptoSystem.families(family1).isRegistered);
        assertTrue(familyCryptoSystem.families(family2).isRegistered);
    }

    function testRegisterIoTDevice() public {
        vm.startPrank(family1);
        familyCryptoSystem.registerIoTDevice("camera");
        (,,,,,,,uint256 securityScore,) = familyCryptoSystem.families(family1);
        assertEq(securityScore, 10);
        vm.stopPrank();
    }

    function testMineBlock() public {
        vm.startPrank(family1);
        familyCryptoSystem.registerIoTDevice("camera");
        vm.warp(block.timestamp + 1 hours);
        familyCryptoSystem.mineBlock();
        (uint256 balance,,,,,,,,) = familyCryptoSystem.families(family1);
        assertGt(balance, 0);
        vm.stopPrank();
    }

    function testMaintenanceCheck() public {
        vm.startPrank(family1);
        bytes32 messageHash = keccak256(abi.encodePacked(family1, block.timestamp));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        familyCryptoSystem.performMaintenanceCheck(signature);
        (,,,,,,,, uint256 lastMaintenanceCheck) = familyCryptoSystem.families(family1);
        assertEq(lastMaintenanceCheck, block.timestamp