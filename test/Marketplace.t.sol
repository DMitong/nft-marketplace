// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../src/Marketplace.sol";

interface IMockNft is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
 }
 
contract ERC721MarketplaceTest is Test {
  using SignatureChecker for address;

  ERC721Marketplace public marketplace;
  uint256 internal creatorPriv;
  uint256 internal spenderPriv;
  address creator;
  address tokenOwner;
  address tokenAddress;
  uint256 tokenID;
  uint256 price;
  uint256 deadline;
  bool executed;
  bool isActive;
  bytes signature;

   function genHash(address _tokenAddress, uint256 _tokenID, uint256 _price, uint256 _deadline) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenAddress, tokenID, price, deadline));
  }

   function setUp() public {
         marketplace = new ERC721Marketplace();

         creatorPriv = 67890;
         creator = vm.addr(creatorPriv);
         tokenAddress = 0xAc4D78798804e2463E7785698d51239CfA768DAd;
         tokenID = 2972;
         price = 2 ether;
         deadline = 2 days;

         IMockNft(tokenAddress).safeMint(creator, tokenID);
    vm.startPrank(creator);
    bytes32 hashMsg = genHash(tokenAddress, tokenID, price, deadline);
    signature = msg.sender.SignatureChecker(hashMsg);
  }

  function testFulfillOrder() public {
    // Create an order to sell the ERC721 token
    bytes32 orderHash = keccak256(abi.encodePacked(tokenAddress, tokenID, price, deadline, creator));

    // Fulfill the order
    marketplace.fulfillOrder(orderHash, signature);

    // Check that the ERC721 token has been transferred to the buyer
    require(IMockNft.ownerOf(tokenID) == address(this), "ERC721 token not transferred to buyer");
  }
}