// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Importing required modules from OpenZeppelin
import "@openzeppelin/contracts/utils/Counters.sol"; // Utility to help with counting token IDs
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For NFT functionality with metadata support
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface for ERC20 tokens
import "@openzeppelin/contracts/access/Ownable.sol"; // Provides ownership management utilities
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Prevents reentrancy attacks

// MyNFT inherits ERC721URIStorage for NFT, Ownable for access control, and ReentrancyGuard for security
contract MyNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter; // Utility to help with counting token IDs
    Counters.Counter private _tokenIds; // A counter to assign token IDs for minted NFTs

    IERC20 public paymentToken; // Variable to hold the ERC20 token used for purchases
    uint256 public tokenPrice; // The price of one NFT in terms of the ERC20 token

    // Constructor to initialize the NFT contract
    constructor(string memory name, string memory symbol, address _paymentToken, uint256 _tokenPrice) ERC721(name, symbol) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken); // Set the ERC20 token used for payment
        tokenPrice = _tokenPrice; // Set the price per token
    }

    // Function to mint a new NFT
    function mintNFT(address recipient, string memory tokenURI) public nonReentrant {
        require(paymentToken.transferFrom(msg.sender, address(this), tokenPrice), "Token transfer failed."); // Transfers ERC20 tokens from user to contract as payment

        _tokenIds.increment(); // Increment the counter to get a new token ID
        uint256 newItemId = _tokenIds.current(); // Store the new token ID

        _mint(recipient, newItemId); // Mint the new NFT to the recipient
        _setTokenURI(newItemId, tokenURI); // Set the URI (metadata) for the newly minted NFT
    }

    // Function to allow the owner to withdraw ERC20 tokens from the contract
    function withdrawTokens(address to, uint256 amount) public onlyOwner {
        require(paymentToken.transfer(to, amount), "Withdrawal failed."); // Transfers specified amount of ERC20 tokens to a given address
    }
}
// When deploying the Solidity contract you provided, the deployment process will prompt you for inputs because the constructor of the contract requires specific parameters. 
//These parameters initialize the contract with necessary settings for its operation. 
//Here’s what each parameter means and an example of what you might enter:

//Parameters for deployment:

//name (string): The name of the NFT collection, e.g., "CryptoArt".
//symbol (string): The symbol or abbreviation for the NFT collection, e.g., "CRT".
//_paymentToken (address): The address of the ERC20 token that will be used for purchasing the NFTs. This needs to be the smart contract address of an already deployed ERC20 token on the same blockchain where you are deploying your NFT contract.
//_tokenPrice (uint256): The price for each NFT, denominated in the ERC20 tokens specified by _paymentToken.

//Example of deployment inputs:

//Name: "CryptoArt"
//ymbol: "CRT"
//ERC20 Token Address: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045" (This is a hypothetical address of an ERC20 token deployed on Ethereum; you need to replace it with the actual contract address of the ERC20 token you intend to use.)
//Token Price: 100 (This means each NFT will cost 100 units of the specified ERC20 token.)

//What happens after deployment?

//After entering these values and deploying the contract:

//Contract initialization: The constructor sets up the NFT contract with the name, symbol, payment token address, and token price you provided. These are critical for the functioning of the NFT contract as they define what token is accepted and how much it costs to mint an NFT.

//Ready to mint: Once deployed, the contract is ready to mint NFTs. Users who wish to mint an NFT will need to:
//1. Approve the NFT contract to spend the ERC20 tokens on their behalf. This is done by calling the approve function on the ERC20 token's contract, specifying the amount they are willing to allow the NFT contract to transfer.
//2. Call the mintNFT function on the NFT contract, specifying their recipient address and the metadata URI for the NFT they wish to mint. They must have sufficient ERC20 tokens and have given enough allowance to cover the NFT price.

//Minting NFTs: When mintNFT is called, the contract checks if the ERC20 token transfer from the caller's address to the contract's address is successful (covering the price of the NFT). If successful, it mints the NFT to the specified recipient and sets its associated metadata URI.
//Token withdrawal: As the owner of the contract (the deployer by default because of the Ownable inheritance), you can withdraw accumulated ERC20 tokens by calling the withdrawTokens function, specifying the recipient address and the amount to withdraw.