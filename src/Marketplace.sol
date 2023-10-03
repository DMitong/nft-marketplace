// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract ERC721Marketplace {
    struct Order {
        address creator;
        address tokenOwner;
        address tokenAddress;
        uint256 tokenID;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool executed;
    }

    mapping(bytes32 => Order) public orders;

    event OrderFulfilled(
        bytes32 orderHash,
        address buyer,
        address seller,
        address tokenAddress,
        uint256 tokenID,
        uint256 price
    );

    // Function to create an ERC721 order
    function createOrder(
        address tokenAddress,
        uint256 tokenID,
        uint256 price,
        bytes memory signature,
        uint256 deadline
    ) external {
        // Verify the signature
        bytes32 orderHash = keccak256(
            abi.encode(tokenAddress, tokenID, price, msg.sender, deadline)
        );
        require(
            SignatureChecker.isValidSignatureNow(
                msg.sender,
                orderHash,
                signature
            ),
            "Invalid signature"
        );

        // Create the order
        Order memory order = Order({
            creator: msg.sender,
            tokenOwner: IERC721(tokenAddress).ownerOf(tokenID),
            tokenAddress: tokenAddress,
            tokenID: tokenID,
            price: price,
            signature: signature,
            deadline: deadline,
            executed: false
        });

        // Store the order
        orders[orderHash] = order;
    }

    // Function to fulfill/executed an ERC721 order
    function fulfillOrder(bytes32 orderHash) external payable {
        Order storage order = orders[orderHash];

        // Verify order conditions
        require(!order.executed, "Order already executed");
        require(block.timestamp <= order.deadline, "Order expired");
        require(msg.value == order.price, "Incorrect amount sent");
        require(
            msg.sender != order.creator,
            "Buyer cannot be the order creator"
        );
        require(
            IERC721(order.tokenAddress).ownerOf(order.tokenID) ==
                order.tokenOwner,
            "Token owner has changed"
        );

        // Verify the signature
        require(
            SignatureChecker.isValidSignatureNow(
                order.tokenOwner,
                orderHash,
                order.signature
            ),
            "Invalid signature"
        );

        // Transfer the token to the buyer
        IERC721(order.tokenAddress).safeTransferFrom(
            order.tokenOwner,
            msg.sender,
            order.tokenID
        );

        // Transfer the payment to the seller
        payable(order.creator).transfer(order.price);

        // Mark the order as executed
        order.executed = true;

        emit OrderFulfilled(
            orderHash,
            msg.sender,
            order.creator,
            order.tokenAddress,
            order.tokenID,
            order.price
        );
    }
}
