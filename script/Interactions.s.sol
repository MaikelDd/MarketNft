// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MarketNft} from "../src/MarketNft.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintMarketNft is Script {
    string public constant Mansion =
        "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MarketNft",
            block.chainid
        );
        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        MarketNft(payable(contractAddress)).mintNft{value: 0.1 ether}(Mansion);
        vm.stopBroadcast();
    }
}
