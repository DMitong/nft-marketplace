// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";

contract MarketplaceTest is Test {
  ERC721Marketplace marketplace;

  function setUp() public {
    marketplace = new ERC721Marketplace();
  }

  function testCreateOrder() public {
    // Create sample data
    address nft = address(1);
    uint256 tokenId = 1;
    address owner = address(2);
    address buyer = address(3);
    uint256 price = 1 ether;

    // Generate signature
    bytes32 hash = marketplace.hashOrder(nft, tokenId, owner, buyer, price);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(hash);

    // Create order
    marketplace.createOrder(nft, tokenId, owner, buyer, price, v, r, s);

  // Verify order created
  Order memory order = marketplace.orderByHash(hash);

  assertEq(order.nft, nft);
  assertEq(order.tokenId, tokenId);
  assertEq(order.buyer, buyer);
  assertEq(order.price, price);
  assertEq(order.status, OrderStatus.Open);

  assertTrue(marketplace.orders(hash) == order);

  vm.expectEmit(true, true, true, true);
  emit OrderCreated(
    nft,
    tokenId, 
    owner,
    buyer,
    price,
    block.timestamp
  );  

  }
}