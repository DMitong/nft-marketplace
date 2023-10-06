// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

contract ERC721Marketplace {
    struct Order {
        address creator;
        // address tokenOwner;
        address tokenAddress;
        uint256 tokenID;
        uint256 price;
        bytes sig;
        uint88 deadline;
        bool isActive;
        bool isExecuted;
    }

    mapping(uint256 => Order) public orders;
    address public admin;
    uint256 public orderId;

    /* ERRORS */
    error NotOwner();
    error NotApproved();
    error MinPriceTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();
    error OrderNotExistent();
    error OrderNotActive();
    error PriceNotMet(int256 difference);
    error OrderExpired();
    error PriceMismatch(uint256 originalPrice);

    event OrderCreated(uint256 indexed orderId, Order);
    event OrderFulfilled(uint256 indexed oderId, Order);
    event OrderEdited(uint256 indexed orderId, Order);

    constructor() {
        admin = msg.sender;
    }

    // Function to create an ERC721 order
    function createOrder(
        Order calldata _order
    ) public returns (uint256 _orderId) {
        // Ensure the creator is the owner of the ERC721 token
        if (ERC721(_order.tokenAddress).ownerOf(_order.tokenID) != msg.sender)
            revert NotOwner();
        if (
            !ERC721(_order.tokenAddress).isApprovedForAll(
                msg.sender,
                address(this)
            )
        ) revert NotApproved();
        if (_order.price < 0.01 ether) revert MinPriceTooLow();
        if (_order.deadline < block.timestamp) revert DeadlineTooSoon();
        if (_order.deadline - block.timestamp < 60 minutes)
            revert MinDurationNotMet();

        // Assert Signature
        if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    _order.tokenAddress,
                    _order.tokenID,
                    _order.price,
                    _order.deadline,
                    _order.creator
                ),
                _order.sig,
                msg.sender
            )
        ) revert InvalidSignature();

        // Create the order and mark it as active
        // bytes32 orderHash = keccak256(
        //    abi.encode(tokenAddress, tokenID, price, msg.sender, deadline)
        // );

        // Append to Storage
        Order storage od = orders[orderId];
        od.tokenAddress = _order.tokenAddress;
        od.tokenID = _order.tokenID;
        od.price = _order.price;
        od.sig = _order.sig;
        od.deadline = uint88(_order.deadline);
        od.creator = msg.sender;
        od.isActive = true;
        od.isExecuted = false;

        // Store the order
        // orders[orderHash] = od;

        // Emit event
        emit OrderCreated(orderId, _order);
        _orderId = orderId;
        orderId++;
        return _orderId;
    }

    // Function to fulfill/execute an ERC721 order
    function fulfillOrder(uint256 _orderId) public payable {
        if (_orderId >= orderId) revert OrderNotExistent();
        Order storage od = orders[_orderId];
        if (od.deadline < block.timestamp) revert OrderExpired();
        if (!od.isActive) revert OrderNotActive();
        if (od.price < msg.value) revert PriceMismatch(od.price);
        if (od.price != msg.value)
            revert PriceNotMet(int256(od.price) - int256(msg.value));

        // Update state
        od.isActive = false;

        // transfer
        ERC721(od.tokenAddress).transferFrom(
            od.creator,
            msg.sender,
            od.tokenID
        );

        // transfer eth
        payable(od.creator).transfer(od.price);

        // Update storage
        emit OrderFulfilled(_orderId, od);
    }

    function editOrder(
        uint256 _orderId,
        uint256 _newPrice,
        bool _active
    ) public {
        if (_orderId >= orderId) revert OrderNotExistent();
        Order storage od = orders[_orderId];
        if (od.creator != msg.sender) revert NotOwner();
        od.price = _newPrice;
        od.isActive = _active;
        emit OrderEdited(_orderId, od);
    }

    // add getter for listing
    function getOrder(uint256 _orderId) public view returns (Order memory) {
        // if (_orderId >= orderId)
        return orders[_orderId];
    }
    //     Order storage order = orders[orderHash];

    //     // Verify order conditions
    //     require(order.isActive, "Order is not active");
    //     require(!order.isExecuted, "Order already executed");
    //     require(block.timestamp <= order.deadline, "Order expired");
    //     require(msg.value >= order.price, "Insufficient ETH sent");

    //     // Verify the signature
    //     // constructorSig(orderHash, signature);

    //     // Transfer the token to the buyer
    //     ERC721(order.tokenAddress).safeTransferFrom(
    //         order.tokenOwner,
    //         msg.sender,
    //         order.tokenID
    //     );

    //     // Transfer the payment to the seller
    //     payable(order.creator).transfer(order.price);

    //     // Mark the order as executed
    //     order.isExecuted = true;
    //     order.isActive = false;

    //     emit OrderFulfilled(
    //         orderHash,
    //         msg.sender,
    //         order.creator,
    //         order.tokenAddress,
    //         order.tokenID,
    //         order.price
    //     );
    // }

    // Function to construct the signature
    // function constructorSig(
    //     bytes32 orderHash,
    //     bytes memory signature
    // ) public view {
    //     bytes32 mHash = keccak256(abi.encodePacked(orderHash));

    //     mHash = keccak256(
    //         abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
    //     );

    //     // Verify the signature
    //     require(
    //         SignatureChecker.isValidSignatureNow(
    //             orders[orderHash].creator,
    //             orderHash,
    //             signature
    //         ),
    //         "Invalid signature"
    //     );
    // }
}
