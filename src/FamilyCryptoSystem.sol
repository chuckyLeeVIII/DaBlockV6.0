// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BridgeableCoin.sol";
import "./GitHubVerifier.sol";
import "./DEXBridge.sol";
import "./MemeToken.sol";
import "./FamilyNFT.sol";
import "./SecuritySystem.sol";

/*
This contract, FamilyCryptoSystem, is the core of a family-based cryptocurrency ecosystem. It integrates various components to create a comprehensive system for families to manage their digital assets, engage in mining, and participate in a decentralized economy. Here's a breakdown of its key features:

1. Family Registration: Families can register using their GitHub accounts, which are verified through the GitHubVerifier contract. This adds a layer of identity verification to the system.

2. Multi-Token Support: The system supports multiple tokens (ETH, POLY, LTC, DOGE) for different types of transactions, allowing for a diverse economic ecosystem.

3. Purchase Types: Families can set allowed purchase types, providing control over how funds are spent within the family unit.

4. Meme Tokens and NFTs: The system includes support for meme tokens and NFTs, adding a layer of digital collectibles and potentially fun, engaging elements to the ecosystem.

5. Mining and Rewards: Families can mine blocks and receive rewards, with mining power influenced by their security score and reputation.

6. Security System: An IoT-based security system is integrated, where families can register devices to increase their security score, which in turn affects their mining rewards.

7. Maintenance Checks: Regular maintenance checks are encouraged to maintain the health of the system and increase family reputation.

8. Cross-Chain Functionality: The system supports bridging tokens across different blockchain networks, enabling interoperability.

9. Decentralized Exchange Integration: A DEX bridge is included for swapping tokens across different chains.

This system aims to create a self-sustaining crypto ecosystem centered around family units, combining elements of traditional cryptocurrencies with unique features like family-based mining, security integration, and cross-chain functionality. It's designed to bring cryptocurrency usage closer to everyday family life while maintaining security and encouraging responsible management of digital assets.
*/

contract FamilyCryptoSystem is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Contract dependencies
    BridgeableCoin public familyCoin;
    GitHubVerifier public githubVerifier;
    DEXBridge public dexBridge;
    MemeToken public memeToken;
    FamilyNFT public familyNFT;
    SecuritySystem public securitySystem;

    // Token interfaces for various cryptocurrencies
    IERC20 public ethToken;
    IERC20 public polyToken;
    IERC20 public ltcToken;
    IERC20 public dogeToken;

    // Enum to represent different types of purchases
    enum PurchaseType { General, Gas, Food, Phone, Wallet, LargeAsset }

    // Struct to represent a family in the system
    struct Family {
        bool isRegistered;
        uint256 balance;
        uint256 reputation;
        uint256 miningPower;
        uint256 lastMiningTimestamp;
        uint256 lastMaintenanceCheck;
        string githubUsername;
        mapping(PurchaseType => bool) allowedPurchaseTypes;
    }

    // Struct to represent NFT ownership
    struct NFTOwnership {
        address owner;
        bool isLocked;
    }

    // Mappings to store family data and NFT ownerships
    mapping(address => Family) public families;
    mapping(address => mapping(uint256 => NFTOwnership)) public nftOwnerships;
    mapping(address => uint256) public familySecurityScore;

    Counters.Counter private _familyIdCounter;

    // Constants for system parameters
    uint256 public constant MINING_COOLDOWN = 1 hours;
    uint256 public constant MAINTENANCE_INTERVAL = 7 days;
    uint256 public constant MINING_REWARD = 10 ether;
    uint256 public constant SECURITY_SCORE_MULTIPLIER = 1e18;

    // Events
    event FamilyRegistered(address indexed familyAddress, uint256 familyId);
    event PurchaseTypeUpdated(address indexed family, PurchaseType purchaseType, bool isAllowed);
    event MemeTokenPurchased(address indexed buyer, uint256 amount);
    event NFTPurchased(address indexed buyer, uint256 tokenId, address nftContract);
    event NFTLocked(address indexed owner, uint256 tokenId, address nftContract);
    event NFTUnlocked(address indexed owner, uint256 tokenId, address nftContract);
    event PaymentMade(address indexed from, address indexed to, address token, uint256 amount, string purpose);
    event MiningReward(address indexed family, uint256 amount);
    event MaintenancePerformed(address indexed family, uint256 timestamp);
    event FamilySecurityScoreUpdated(address indexed family, uint256 newScore);

    // Constructor to initialize the contract with necessary dependencies
    constructor(
        address _githubVerifier,
        address _dexBridge,
        address _memeToken,
        address _ethToken,
        address _polyToken,
        address _ltcToken,
        address _dogeToken
    ) {
        githubVerifier = GitHubVerifier(_githubVerifier);
        dexBridge = DEXBridge(_dexBridge);
        familyCoin = new BridgeableCoin("FamilyCoin", "FAM");
        memeToken = MemeToken(_memeToken);
        familyNFT = new FamilyNFT();
        securitySystem = new SecuritySystem();
        ethToken = IERC20(_ethToken);
        polyToken = IERC20(_polyToken);
        ltcToken = IERC20(_ltcToken);
        dogeToken = IERC20(_dogeToken);
    }

    // Function to register a new family
    function registerFamily(string memory _githubUsername) external {
        require(!families[msg.sender].isRegistered, "Family already registered");
        require(githubVerifier.verifiedAccounts(_githubUsername), "GitHub account not verified");

        uint256 familyId = _familyIdCounter.current();
        _familyIdCounter.increment();

        families[msg.sender] = Family({
            isRegistered: true,
            balance: 0,
            reputation: 0,
            miningPower: 1,
            lastMiningTimestamp: 0,
            lastMaintenanceCheck: block.timestamp,
            githubUsername: _githubUsername
        });

        familyNFT.mint(msg.sender, familyId);

        emit FamilyRegistered(msg.sender, familyId);
    }

    // Function to update allowed purchase types for a family
    function updatePurchaseType(PurchaseType _purchaseType, bool _isAllowed) external {
        require(families[msg.sender].isRegistered, "Family not registered");
        families[msg.sender].allowedPurchaseTypes[_purchaseType] = _isAllowed;
        emit PurchaseTypeUpdated(msg.sender, _purchaseType, _isAllowed);
    }

    // Function to purchase Meme tokens
    function purchaseMemeToken(uint256 _amount) external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(families[msg.sender].balance >= _amount, "Insufficient balance");

        families[msg.sender].balance = families[msg.sender].balance.sub(_amount);
        memeToken.mint(msg.sender, _amount);

        emit MemeTokenPurchased(msg.sender, _amount);
    }

    // Function to purchase an NFT
    function purchaseNFT(address nftContract, uint256 tokenId, uint256 price) external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(families[msg.sender].balance >= price, "Insufficient balance");

        families[msg.sender].balance = families[msg.sender].balance.sub(price);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        nftOwnerships[nftContract][tokenId] = NFTOwnership({
            owner: msg.sender,
            isLocked: false
        });

        emit NFTPurchased(msg.sender, tokenId, nftContract);
    }

    // Function to lock an NFT
    function lockNFT(address nftContract, uint256 tokenId) external {
        require(nftOwnerships[nftContract][tokenId].owner == msg.sender, "Not the owner");
        require(!nftOwnerships[nftContract][tokenId].isLocked, "NFT already locked");

        nftOwnerships[nftContract][tokenId].isLocked = true;
        emit NFTLocked(msg.sender, tokenId, nftContract);
    }

    // Function to unlock an NFT
    function unlockNFT(address nftContract, uint256 tokenId) external {
        require(nftOwnerships[nftContract][tokenId].owner == msg.sender, "Not the owner");
        require(nftOwnerships[nftContract][tokenId].isLocked, "NFT not locked");

        nftOwnerships[nftContract][tokenId].isLocked = false;
        emit NFTUnlocked(msg.sender, tokenId, nftContract);
    }

    // Function to transfer an NFT
    function transferNFT(address to, address nftContract, uint256 tokenId) external {
        require(nftOwnerships[nftContract][tokenId].owner == msg.sender, "Not the owner");
        require(!nftOwnerships[nftContract][tokenId].isLocked, "NFT is locked");

        nftOwnerships[nftContract][tokenId].owner = to;
        IERC721(nftContract).transferFrom(msg.sender, to, tokenId);
    }

    // Function to make a payment
    function makePayment(address to, address token, uint256 amount, string memory purpose) external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(families[to].isRegistered, "Recipient family not registered");
        
        IERC20(token).transferFrom(msg.sender, to, amount);
        
        emit PaymentMade(msg.sender, to, token, amount, purpose);
    }

    // Function to pay utilities
    function payUtilities(address to, uint256 amount) external {
        makePayment(to, address(ethToken), amount, "Utilities");
    }

    // Function to pay rent
    function payRent(address to, uint256 amount) external {
        makePayment(to, address(polyToken), amount, "Rent");
    }

    // Function to pay for food
    function payForFood(address to, uint256 amount) external {
        makePayment(to, address(ltcToken), amount, "Food");
    }

    // Function to pay for personal expenses
    function payPersonalExpenses(address to, uint256 amount) external {
        makePayment(to, address(dogeToken), amount, "Personal Expenses");
    }

    // Function to mine a block and receive rewards
    function mineBlock() external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(block.timestamp >= families[msg.sender].lastMiningTimestamp + MINING_COOLDOWN, "Mining cooldown not met");

        uint256 securityBonus = familySecurityScore[msg.sender].mul(SECURITY_SCORE_MULTIPLIER).div(100);
        uint256 reward = MINING_REWARD.add(securityBonus);

        families[msg.sender].balance = families[msg.sender].balance.add(reward);
        families[msg.sender].lastMiningTimestamp = block.timestamp;
        families[msg.sender].reputation = families[msg.sender].reputation.add(1);

        emit MiningReward(msg.sender, reward);
    }

    // Function to perform maintenance and increase reputation
    function performMaintenance() external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(block.timestamp >= families[msg.sender].lastMaintenanceCheck + MAINTENANCE_INTERVAL, "Maintenance interval not met");

        families[msg.sender].lastMaintenanceCheck = block.timestamp;
        families[msg.sender].reputation = families[msg.sender].reputation.add(5);

        emit MaintenancePerformed(msg.sender, block.timestamp);
    }

    // Function to update a family's security score
    function updateFamilySecurityScore(address family, uint256 newScore) external {
        require(msg.sender == address(securitySystem), "Only SecuritySystem can update scores");
        familySecurityScore[family] = newScore;
        emit FamilySecurityScoreUpdated(family, newScore);
    }

    // Function to initiate a token bridge request
    function bridgeTokens(uint256 amount, uint256 targetChainId) external {
        require(families[msg.sender].isRegistered, "Family not registered");
        require(families[msg.sender].balance >= amount, "Insufficient balance");

        families[msg.sender].balance = families[msg.sender].balance.sub(amount);
        familyCoin.initiateBridgeRequest(amount, targetChainId);
    }

    // Function to complete a token bridge request
    function completeBridgeRequest(address to, uint256 amount, uint256 sourceChainId, bytes memory signature) external onlyOwner {
        familyCoin.completeBridgeRequest(to, amount, sourceChainId, signature);
        families[to].balance = families[to].balance.add(amount);
    }
}