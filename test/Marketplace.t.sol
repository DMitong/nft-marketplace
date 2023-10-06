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
        erc721 = new TestNFT();

        // Create user accounts
        (user1, privKey1) = mkaddr("user1");
        (user2, privKey2) = mkaddr("user2");

        orderDetails = ERC721Marketplace.Order({
            tokenAddress: address(erc721),
            tokenID: 1,
            price: 1 ether,
            sig: "",
            deadline: 0,
            creator: address(0),
            isActive: false,
            isExecuted: false
        });

        erc721.mint(user1, 1);
    }

    // Tests
}
