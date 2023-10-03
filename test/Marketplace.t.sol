// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";

contract MarketplaceTest is Test {

  ERC721Marketplace marketplace;

  // Mock NFT contract
  contract MockNFT {
    function safeTransferFrom(address, address, uint256) external {}
  }

  MockNFT nft;

  function setUp() public {
    marketplace = new ERC721Marketplace();
    nft = new MockNFT();
  }

  function testCreateOrder() public {
    // Create sample data
    address owner = address(1);
    address buyer = address(2);
    uint256 tokenId = 1;
    uint256 price = 1 ether;

    // Generate signature
    bytes32 hash = marketplace.hashOrder(address(nft), tokenId, owner, buyer, price);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(hash);

    // Create order
    marketplace.createOrder(address(nft), tokenId, owner, buyer, price, v, r, s);

    // Verify order created
    Order memory order = marketplace.orderByHash(hash);

    assertEq(order.nft, address(nft));
    assertEq(order.tokenId, tokenId);
    assertEq(order.buyer, buyer);
    assertEq(order.price, price);
    assertEq(order.status, OrderStatus.Open);

    assertTrue(marketplace.orders(hash) == order);

    // Test events
    vm.expectEmit(true, true, false, true);
    emit OrderCreated(
      address(nft),
      tokenId,
      owner, 
      buyer,
      price,
      block.timestamp
    );
  }

  function testFulfillOrder() public {
    // Create order
    vm.prank(address(1));
    marketplace.createOrder(address(nft), 1, address(1), address(2), 1 ether, "", "", "");
    bytes32 hash = marketplace.hashOrder(address(nft), 1, address(1), address(2), 1 ether);

    // Fulfill order
    vm.prank(address(2));
    marketplace.fulfillOrder{value: 1 ether}(hash);

    // Test state change
    Order memory order = marketplace.orderByHash(hash);
    assertEq(order.status, OrderStatus.Fulfilled);

    // Test events
    vm.expectEmit(true, true, false, true);
    emit OrderFulfilled(hash, address(2), address(1), 1 ether);

    // Test invalid cases
    vm.warp(block.timestamp + 1 days);
    vm.expectRevert("Order expired");
    marketplace.fulfillOrder(hash);

    vm.prank(address(1));
    nft.safeTransferFrom(address(1), address(3), 1); 
    vm.expectRevert("Token owner changed");
    marketplace.fulfillOrder(hash);
  }

}