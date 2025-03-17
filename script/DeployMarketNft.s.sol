// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MarketNft} from "../src/MarketNft.sol";

contract DeployMarketNft is Script {
    function run() external returns (MarketNft) {
        vm.startBroadcast();
        MarketNft nft = new MarketNft(100, 0.1 ether);
        vm.stopBroadcast();
        return nft;
    }
}
