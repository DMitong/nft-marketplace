## ERC721 Marketplace
This is a smart contract for a decentralized ERC721 marketplace, where users can create and fulfill orders for buying and selling ERC721 tokens.

### Features
-   Create orders to sell ERC721 tokens
-   Fulfill orders to buy ERC721 tokens
-   Edit orders (price and active status)
-   View order details

### Usage
To create an order, you must first approve the marketplace contract to transfer the ERC721 token on your behalf. You can do this using the ERC721.approve() function.

Once you have approved the marketplace contract, you can create an order using the createOrder() function. This function takes an Order object as input, which includes the following fields:

-   **tokenAddress:** The address of the ERC721 token contract
-   **tokenID:** The ID of the ERC721 token
-   **price:** The price of the ERC721 token in ETH
-   **sig:** The signature of the order, which is used to verify that the order was created by the owner of the ERC721 token
To fulfill an order, you must send ETH to the marketplace contract equal to the price of the order. You can then call the fulfillOrder() function with the ID of the order you want to fulfill.

To edit an order, you must call the editOrder() function with the ID of the order you want to edit, the new price, and the new active status.

To view the details of an order, you can call the getOrder() function with the ID of the order.

#### Example
```shell
// Create an order to sell an ERC721 token
Order order = Order({
  tokenAddress: "0x1234567890ABCDEF",
  tokenID: 1,
  price: 1 ether,
  sig: "0x1234567890ABCDEF"
});

// Create the order
uint256 orderId = marketplace.createOrder(order);

// Fulfill the order
marketplace.fulfillOrder(orderId, {value: 1 ether});

// Edit the order
marketplace.editOrder(orderId, 2 ether, false);

// View the order details
Order orderDetails = marketplace.getOrder(orderId);
```

### Deployment
To deploy this smart contract, you can use the following command:

```shell
forge deploy
```
This will deploy the smart contract to the current network. You can then find the address of the deployed contract in the deployment directory.

### Testing
To test this smart contract, you can use the following command:

```shell
forge test
This will run all of the tests in the test directory.
```

### License
This smart contract is licensed under the UNLICENSED license.
