// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BridgeableCoin.sol";

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract DEXBridge is Ownable {
    mapping(uint256 => address) public chainToRouter;
    mapping(uint256 => address) public chainToFamilyCoin;
    mapping(uint256 => mapping(address => address)) public bridgeTokenPairs;

    event BridgeSwap(address indexed from, uint256 fromChainId, uint256 toChainId, uint256 amount);
    event BridgeSwapCompleted(address indexed to, uint256 fromChainId, uint256 toChainId, uint256 amount);

    function setRouter(uint256 chainId, address routerAddress) external onlyOwner {
        chainToRouter[chainId] = routerAddress;
    }

    function setFamilyCoin(uint256 chainId, address coinAddress) external onlyOwner {
        chainToFamilyCoin[chainId] = coinAddress;
    }

    function setBridgeTokenPair(uint256 chainId, address familyCoin, address bridgeToken) external onlyOwner {
        bridgeTokenPairs[chainId][familyCoin] = bridgeToken;
    }

    function bridgeSwap(uint256 fromChainId, uint256 toChainId, uint256 amount) external {
        require(chainToRouter[fromChainId] != address(0), "Source chain not supported");
        require(chainToRouter[toChainId] != address(0), "Target chain not supported");
        require(chainToFamilyCoin[fromChainId] != address(0), "Source chain FamilyCoin not set");
        require(chainToFamilyCoin[toChainId] != address(0), "Target chain FamilyCoin not set");

        address sourceFamilyCoin = chainToFamilyCoin[fromChainId];
        address sourceBridgeToken = bridgeTokenPairs[fromChainId][sourceFamilyCoin];
        require(sourceBridgeToken != address(0), "Bridge token not set for source chain");

        IERC20(sourceFamilyCoin).transferFrom(msg.sender, address(this), amount);

        // Approve router to spend family coins
        IERC20(sourceFamilyCoin).approve(chainToRouter[fromChainId], amount);

        // Perform the swap on the source chain's DEX
        address[] memory path = new address[](2);
        path[0] = sourceFamilyCoin;
        path[1] = sourceBridgeToken;

        IDEXRouter(chainToRouter[fromChainId]).swapExactTokensForTokens(
            amount,
            0, // We're not setting a minimum amount out for simplicity
            path,
            address(this),
            block.timestamp + 15 minutes
        );

        emit BridgeSwap(msg.sender, fromChainId, toChainId, amount);

        // The actual transfer to the target chain would be handled off-chain
        // and then finalized on the target chain
    }

    function completeBridgeSwap(address to, uint256 amount, uint256 fromChainId, uint256 toChainId) external onlyOwner {
        require(chainToFamilyCoin[toChainId] != address(0), "Target chain FamilyCoin not set");
        address targetFamilyCoin = chainToFamilyCoin[toChainId];
        address targetBridgeToken = bridgeTokenPairs[toChainId][targetFamilyCoin];
        require(targetBridgeToken != address(0), "Bridge token not set for target chain");

        // Approve router to spend bridge tokens
        IERC20(targetBridgeToken).approve(chainToRouter[toChainId], amount);

        // Perform the swap on the target chain's DEX
        address[] memory path = new address[](2);
        path[0] = targetBridgeToken;
        path[1] = targetFamilyCoin;

        IDEXRouter(chainToRouter[toChainId]).swapExactTokensForTokens(
            amount,
            0, // We're not setting a minimum amount out for simplicity
            path,
            to,
            block.timestamp + 15 minutes
        );

        emit BridgeSwapCompleted(to, fromChainId, toChainId, amount);
    }
}