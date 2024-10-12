# FamilyCryptoSystem Project Overview

This project implements a comprehensive family-based cryptocurrency ecosystem with various interconnected components. Here's an overview of the key contracts and their functionalities:

1. FamilyCryptoSystem.sol
   - Core contract managing family registration, transactions, and interactions
   - Integrates with other components like MemeToken, SecuritySystem, and cross-chain functionality

2. MemeToken.sol
   - ERC20 token with additional NFT-like features
   - Allows minting, locking, and unlocking of Meme NFTs

3. BridgeableCoin.sol
   - Enables cross-chain transfers of the family cryptocurrency
   - Implements security measures to prevent malicious bridging attempts

4. GitHubVerifier.sol
   - Verifies GitHub accounts for family registration
   - Manages reputation scores for verified accounts

5. DEXBridge.sol
   - Facilitates token swaps across different blockchain networks
   - Integrates with decentralized exchanges on various chains

6. FamilyNFT.sol
   - Simple ERC721 contract for minting family NFTs

7. SecuritySystem.sol
   - Manages IoT devices for family security
   - Calculates and updates family security scores

8. BridgeOracle.sol
   - Handles cross-chain communication for bridge requests

The project also includes test files and deployment scripts for a complete development environment.

## Key Features

- Family-based cryptocurrency management
- Cross-chain functionality
- Integration with IoT devices for security
- Meme tokens and NFTs
- GitHub account verification
- Decentralized exchange integration

## Development and Testing

The project uses Hardhat for development and testing. To get started:

1. Install dependencies: `npm install`
2. Compile contracts: `npx hardhat compile`
3. Run tests: `npx hardhat test`
4. Deploy: `npx hardhat run scripts/deploy.js`

For more detailed information on each component, please refer to the individual contract files and their comments.