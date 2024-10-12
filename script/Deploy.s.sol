// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/FamilyCryptoSystem.sol";
import "../src/GitHubVerifier.sol";
import "../src/DEXBridge.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GitHubVerifier githubVerifier = new GitHubVerifier();
        DEXBridge dexBridge = new DEXBridge();
        FamilyCryptoSystem familyCryptoSystem = new FamilyCryptoSystem(address(githubVerifier), address(dexBridge));

        // Set up DEX Bridge
        dexBridge.setFamilyCoin(block.chainid, address(familyCryptoSystem.familyCoin()));
        
        // Set up routers for supported chains (example addresses, replace with actual addresses)
        dexBridge.setRouter(1, address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)); // Uniswap V2 Router on Ethereum
        dexBridge.setRouter(56, address(0x10ED43C718714eb63d5aA57B78B54704E256024E)); // PancakeSwap Router on BSC
        dexBridge.setRouter(250, address(0xF491e7B69E4244ad4002BC14e878a34207E38c29)); // SpookySwap Router on Fantom

        // Set up bridge token pairs (example addresses, replace with actual addresses)
        dexBridge.setBridgeTokenPair(1, address(familyCryptoSystem.familyCoin()), address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // USDC on Ethereum
        dexBridge.setBridgeTokenPair(56, address(familyCryptoSystem.familyCoin()), address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)); // BUSD on BSC
        dexBridge.setBridgeTokenPair(250, address(familyCryptoSystem.familyCoin()), address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75)); // USDC on Fantom

        vm.stopBroadcast();
    }
}