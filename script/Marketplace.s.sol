// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ERC721Marketplace} from "../src/Marketplace.sol";

contract MarketplaceScript is Script {
    function setUp() public {}

    function run() external {
        vm.startBroadcast();
        
        new ERC721Marketplace();

        vm.stopBroadcast();
    }
}