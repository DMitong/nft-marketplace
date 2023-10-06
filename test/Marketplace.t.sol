// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../src/Marketplace.sol";
import "../src/MockNFT.sol";
import "./Helpers.sol";

contract Marketplace is
    Helpers // Setup
{
    ERC721Marketplace marketplace;
    TestNFT erc721;

    uint256 currentOrdersID;

    address user1;
    address user2;

    uint256 privKey1;
    uint256 privKey2;

    ERC721Marketplace.Order orderDetails;

    function setUp() public {
        marketplace = new ERC721Marketplace();
        erc721 = new TestNFT;

        // Create user accounts
        (user1, privKey1) = mkaddr("user1");
        (user2, privKey2) = mkaddr("user2");
    }

    // Tests

    function testCreateOrder() public {
        // Create order
        uint256 orderId = marketplace.createOrder({
            tokenAddress: erc721Address,
            tokenID: 1,
            price: 1 ether,
            sig: constructSig(
                erc721Address,
                1,
                1 ether,
                1000000000000,
                user1,
                user1.privateKey
            ),
            deadline: 1000000000000
        });

        // Verify order created
        Order memory order = marketplace.getOrder(orderId);
        assertEq(order.tokenAddress, erc721Address);
        assertEq(order.tokenID, 1);
        assertEq(order.price, 1 ether);
        assertEq(
            order.sig,
            constructSig(
                erc721Address,
                1,
                1 ether,
                1000000000000,
                user1,
                user1.privateKey
            )
        );
        assertEq(order.deadline, 1000000000000);
        assertEq(order.isActive, true);
    }

    function testFulfillOrder() public {
        // Create order
        uint256 orderId = marketplace.createOrder({
            tokenAddress: erc721Address,
            tokenID: 1,
            price: 1 ether,
            sig: constructSig(
                erc721Address,
                1,
                1 ether,
                1000000000000,
                user1,
                user1.privateKey
            ),
            deadline: 1000000000000
        });

        // Switch signer to user2
        switchSigner(user2);

        // Fulfill order
        marketplace.fulfillOrder{value: 1 ether}(orderId);

        // Verify order fulfilled
        Order memory order = marketplace.getOrder(orderId);
        assertEq(order.isActive, false);

        // Verify user2 now owns ERC721 token
        assertEq(ERC721(erc721Address).ownerOf(1), user2);
    }
}

// interface IMockNft is IERC721 {
//     function safeMint(address to, uint256 tokenId) external;
// }
// contract ERC721MarketplaceTest is Test {
//     using SignatureChecker for address;
//     ERC721Marketplace public marketplace;
//     uint256 internal creatorPriv;
//     uint256 internal spenderPriv;
//     address creator;
//     address tokenOwner;
//     address tokenAddress;
//     uint256 tokenID;
//     uint256 price;
//     uint256 deadline;
//     bool executed;
//     bool isActive;
//     bytes signature;
//     function genHash(
//         address _tokenAddress,
//         uint256 _tokenID,
//         uint256 _price,
//         uint256 _deadline
//     ) public pure returns (bytes32) {
//         return
//             keccak256(abi.encodePacked(tokenAddress, tokenID, price, deadline));
//     }
//     function setUp() public {
//         marketplace = new ERC721Marketplace();
//         creatorPriv = 67890;
//         creator = vm.addr(creatorPriv);
//         tokenAddress = 0xAc4D78798804e2463E7785698d51239CfA768DAd;
//         tokenID = 2972;
//         price = 2 ether;
//         deadline = 2 days;
//         IMockNft(tokenAddress).safeMint(creator, tokenID);
//         vm.startPrank(creator);
//         bytes32 hashMsg = genHash(tokenAddress, tokenID, price, deadline);
//         signature = msg.sender.constructorSig(hashMsg);
//     }
//     function testFulfillOrder() public {
//         // Create an order to sell the ERC721 token
//         bytes32 orderHash = keccak256(
//             abi.encodePacked(tokenAddress, tokenID, price, deadline, creator)
//         );
//         // Fulfill the order
//         marketplace.fulfillOrder(orderHash, signature);
//         // Check that the ERC721 token has been transferred to the buyer
//         require(
//             IMockNft.ownerOf(tokenID) == address(this),
//             "ERC721 token not transferred to buyer"
//         );
//     }
//     function testCreateAndFulfillOrder() public {
//         vm.startPrank(creator);
//         bytes32 orderHash = marketplace.createOrder(
//             IMockNft,
//             tokenID,
//             1 ether,
//             block.timestamp + 1 days
//         );
//         vm.stopPrank();
//         bytes memory signature = constructorSig(orderHash);
//         vm.prank(buyer);
//         marketplace.fulfillOrder(orderHash, signature);
//         assertEq(IERC721(nftContract).ownerOf(tokenId), buyer);
//         assertTrue(emittedOrderFulfilled(orderHash));
//     }
//     function testCreateOrderFails() public {
//         vm.expectRevert("Not approved to transfer NFT");
//         marketplace.createOrder(
//             nftContract,
//             tokenId,
//             1 ether,
//             block.timestamp + 1 days
//         );
//         vm.expectRevert("Invalid price");
//         marketplace.createOrder(
//             nftContract,
//             tokenId,
//             0,
//             block.timestamp + 1 days
//         );
//         vm.expectRevert("Deadline expired");
//         marketplace.createOrder(
//             nftContract,
//             tokenId,
//             1 ether,
//             block.timestamp - 1 days
//         );
//     }
//     function testFulfillOrderFails() public {
//         bytes32 orderHash = keccak256(
//             abi.encodePacked(
//                 nftContract,
//                 tokenId,
//                 1 ether,
//                 block.timestamp + 1 days,
//                 creator
//             )
//         );
//         vm.expectRevert("Order not found");
//         marketplace.fulfillOrder(bytes32(0), "");
//         vm.expectRevert("Order inactive");
//         marketplace.fulfillOrder(orderHash, "");
//         // Create valid order
//         marketplace.createOrder(
//             nftContract,
//             tokenId,
//             1 ether,
//             block.timestamp + 1 days
//         );
//         vm.expectRevert("Insufficient ETH");
//         marketplace.fulfillOrder{value: 0.5 ether}(
//             orderHash,
//             signOrder(orderHash)
//         );
//         vm.expectRevert("Deadline expired");
//         vm.warp(block.timestamp + 2 days);
//         marketplace.fulfillOrder{value: 1 ether}(
//             orderHash,
//             signOrder(orderHash)
//         );
//         vm.expectRevert("Invalid signature");
//         marketplace.fulfillOrder{value: 1 ether}(orderHash, "");
//     }
//}
