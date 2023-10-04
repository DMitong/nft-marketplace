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
    uint256 deadline;
    bool isActive;
    bool isExecuted;
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
    uint256 deadline
  ) external {
    // Ensure the creator is the owner of the ERC721 token
    require(
      IERC721(tokenAddress).ownerOf(tokenID) == msg.sender,
      "Only the token owner can create an order"
    );

    // Create the order and mark it as active
    bytes32 orderHash = keccak256(
      abi.encode(tokenAddress, tokenID, price, msg.sender, deadline)
    );

    Order memory order = Order({
      creator: msg.sender,
      tokenOwner: msg.sender,
      tokenAddress: tokenAddress,
      tokenID: tokenID,
      price: price,
      deadline: deadline,
      isActive: true,
       isExecuted: false
    });

    // Store the order
    orders[orderHash] = order;
  }

  // Function to fulfill/executed an ERC721 order
  function fulfillOrder(
    bytes32 orderHash,
    bytes memory signature
  ) external payable {
    Order storage order = orders[orderHash];

    // Verify order conditions
    require(order.isActive, "Order is not active");
    require(!order.isExecuted, "Order already executed");
    require(block.timestamp <= order.deadline, "Order expired");
    require(msg.value >= order.price, "Insufficient ETH sent");

    // Verify the signature
    constructorSig(orderHash, signature);

    // Transfer the token to the buyer
    IERC721(order.tokenAddress).safeTransferFrom(
      order.tokenOwner,
      msg.sender,
      order.tokenID
    );

    // Transfer the payment to the seller
    payable(order.creator).transfer(order.price);

    // Mark the order as executed
    order.isExecuted = true;
    order.isActive = false;

    emit OrderFulfilled(
      orderHash,
      msg.sender,
      order.creator,
      order.tokenAddress,
      order.tokenID,
      order.price
    );
  }

    // Function to construct the signature
    function constructorSig(
        bytes32 orderHash,
        bytes memory signature
    ) public view {
        bytes32 mHash = keccak256(abi.encodePacked(orderHash));

        mHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash));

        // Verify the signature
        require(
            SignatureChecker.isValidSignatureNow(
                orders[orderHash].creator,
                orderHash,
                signature
            ),
            "Invalid signature"
        );
    }
}
