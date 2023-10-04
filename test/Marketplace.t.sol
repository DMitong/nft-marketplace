// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Marketplace.sol"; 
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract MarketplaceTest is Test, ERC721Holder {

  ERC721Marketplace marketplace;

  address creator = vm.addr(1);
  address buyer = vm.addr(2);

  uint256 tokenId = 1;
  address nftContract = 0x0000000000000000000000000000000000000001;

  function setUp() public {
    marketplace = new ERC721Marketplace();
  }

  function testCreateAndFulfillOrder() public {
    vm.startPrank(creator);
    bytes32 orderHash = marketplace.createOrder(nftContract, tokenId, 1 ether, block.timestamp + 1 days);
    vm.stopPrank();

    bytes memory signature = signOrder(orderHash);

    vm.prank(buyer);
    marketplace.fulfillOrder(orderHash, signature);

    assertEq(IERC721(nftContract).ownerOf(tokenId), buyer);

    assertTrue(emittedOrderFulfilled(orderHash));
  }

  function signOrder(bytes32 orderHash) public view returns (bytes memory) {
    return vm.sign(creator, orderHash); 
  }

  function emittedOrderFulfilled(bytes32 orderHash) public view returns (bool) {
    return logExists(ERC721Marketplace.OrderFulfilled(orderHash, buyer, creator, nftContract, tokenId, 1 ether)); 
  }

}