// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
The MemeToken contract is a crucial part of the FamilyCryptoSystem, introducing a fun and engaging element to the ecosystem. It combines traditional ERC20 token functionality with NFT-like features, creating a unique hybrid token. Here's an overview of its key components:

1. ERC20 Functionality: The contract inherits from OpenZeppelin's ERC20 implementation, providing standard token features like transfers and balance tracking.

2. Meme NFTs: In addition to being a fungible token, MemeToken also allows the creation of unique Meme NFTs. These NFTs have properties like a token ID, URI (for metadata or image links), and a lock status.

3. Controlled Minting: Only the FamilyCryptoSystem contract can mint new tokens, ensuring that token creation is managed within the ecosystem's rules.

4. Restricted Transfers: Token transfers can only be initiated through the FamilyCryptoSystem contract, providing an additional layer of control and integration with the broader ecosystem.

5. NFT Management: Users can mint, lock, and unlock Meme NFTs, adding a collectible aspect to the token.

6. Ownership Tracking: The contract keeps track of which Meme NFTs are owned by each user, allowing for easy querying of a user's collection.

This hybrid approach creates a versatile token that can be used for both traditional cryptocurrency functions and as a platform for digital collectibles, all within the context of the family-based crypto ecosystem.
*/

contract MemeToken is ERC20, Ownable {
    using Counters for Counters.Counter;

    // Address of the FamilyCryptoSystem contract
    address public familyCryptoSystem;
    Counters.Counter private _tokenIdCounter;

    // Struct to represent a Meme NFT
    struct MemeNFT {
        uint256 tokenId;
        string uri;
        bool isLocked;
    }

    // Mappings to store Meme NFT data
    mapping(uint256 => MemeNFT) public memeNFTs;
    mapping(address => uint256[]) public userMemeNFTs;

    // Events
    event MemeNFTMinted(address indexed owner, uint256 tokenId, string uri);
    event MemeNFTLocked(uint256 tokenId);
    event MemeNFTUnlocked(uint256 tokenId);

    // Constructor to initialize the token with a name and symbol
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Function to set the address of the FamilyCryptoSystem contract
    function setFamilyCryptoSystem(address _familyCryptoSystem) external onlyOwner {
        familyCryptoSystem = _familyCryptoSystem;
    }

    // Function to mint new tokens (only callable by FamilyCryptoSystem)
    function mint(address to, uint256 amount) external {
        require(msg.sender == familyCryptoSystem, "Only FamilyCryptoSystem can mint");
        _mint(to, amount);
    }

    // Override transfer function to ensure it's only called through FamilyCryptoSystem
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(msg.sender == familyCryptoSystem, "Transfers can only be initiated through FamilyCryptoSystem");
        return super.transfer(recipient, amount);
    }

    // Override transferFrom function to ensure it's only called through FamilyCryptoSystem
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(msg.sender == familyCryptoSystem, "Transfers can only be initiated through FamilyCryptoSystem");
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to mint a Meme NFT
    function mintMemeNFT(address to, string memory uri) external {
        require(msg.sender == familyCryptoSystem, "Only FamilyCryptoSystem can mint NFTs");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        memeNFTs[tokenId] = MemeNFT(tokenId, uri, false);
        userMemeNFTs[to].push(tokenId);

        emit MemeNFTMinted(to, tokenId, uri);
    }

    // Function to lock a Meme NFT
    function lockMemeNFT(uint256 tokenId) external {
        require(msg.sender == familyCryptoSystem, "Only FamilyCryptoSystem can lock NFTs");
        require(!memeNFTs[tokenId].isLocked, "NFT is already locked");

        memeNFTs[tokenId].isLocked = true;
        emit MemeNFTLocked(tokenId);
    }

    // Function to unlock a Meme NFT
    function unlockMemeNFT(uint256 tokenId) external {
        require(msg.sender == familyCryptoSystem, "Only FamilyCryptoSystem can unlock NFTs");
        require(memeNFTs[tokenId].isLocked, "NFT is not locked");

        memeNFTs[tokenId].isLocked = false;
        emit MemeNFTUnlocked(tokenId);
    }

    // Function to get all Meme NFTs owned by a user
    function getUserMemeNFTs(address user) external view returns (uint256[] memory) {
        return userMemeNFTs[user];
    }

    // Function to get details of a specific Meme NFT
    function getMemeNFTDetails(uint256 tokenId) external view returns (MemeNFT memory) {
        return memeNFTs[tokenId];
    }
}