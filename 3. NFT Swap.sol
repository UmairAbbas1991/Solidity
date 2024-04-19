// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Includes IERC721Receiver interface
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTSwap is ReentrancyGuard, IERC721Receiver {
    struct Swap {
        address[2] parties;
        address[2] contracts;
        uint256[2] tokenIds;
        bool[2] deposited;
    }

    // Private mapping of swaps
    mapping(uint256 => Swap) private swaps;
    uint256 public nextSwapId;

    event SwapCreated(uint256 indexed swapId, address indexed party1, address indexed party2, address contract1, address contract2, uint256 tokenId1, uint256 tokenId2);
    event NFTDeposited(uint256 indexed swapId, address depositor);
    event Swapped(uint256 indexed swapId);

    // Function to create a new swap
    function createSwap(
        address _party2,
        address _contract1,
        address _contract2,
        uint256 _tokenId1,
        uint256 _tokenId2
    ) external {
        swaps[nextSwapId] = Swap({
            parties: [msg.sender, _party2],
            contracts: [_contract1, _contract2],
            tokenIds: [_tokenId1, _tokenId2],
            deposited: [false, false]
        });

        emit SwapCreated(nextSwapId, msg.sender, _party2, _contract1, _contract2, _tokenId1, _tokenId2);
        nextSwapId++;
    }

    // Function to allow parties to deposit their NFTs
    function depositNFT(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        int256 index = _findIndex(msg.sender, swap.parties);

        require(index != -1, "Not part of this swap");
        require(!swap.deposited[uint256(index)], "Already deposited");

        IERC721 tokenContract = IERC721(swap.contracts[uint256(index)]);
        tokenContract.safeTransferFrom(msg.sender, address(this), swap.tokenIds[uint256(index)], "");
        swap.deposited[uint256(index)] = true;

        emit NFTDeposited(swapId, msg.sender);
    }

    // Function to execute the swap
    function executeSwap(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        require(swap.deposited[0] && swap.deposited[1], "Both NFTs must be deposited");

        IERC721(swap.contracts[0]).safeTransferFrom(address(this), swap.parties[1], swap.tokenIds[0], "");
        IERC721(swap.contracts[1]).safeTransferFrom(address(this), swap.parties[0], swap.tokenIds[1], "");

        emit Swapped(swapId);
    }

    // Public getter to access swap details
    function getSwap(uint256 swapId) external view returns (Swap memory) {
        return swaps[swapId];
    }

    // IERC721Receiver hook
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Helper function to find the index of an address in the parties array
function _findIndex(address addr, address[2] memory addresses) private pure returns (int256) {
    for (uint256 i = 0; i < 2; i++) {
        if (addresses[i] == addr) {
            return int256(i);
        }
    }
    return -1;
}
}