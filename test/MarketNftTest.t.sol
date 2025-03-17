// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MarketNft} from "../src/MarketNft.sol";
import {DeployMarketNft} from "../script/DeployMarketNft.s.sol";

contract MarketNftTest is Test {
    MarketNft public marketNft;
    DeployMarketNft public deployer;

    address public OWNER = makeAddr("owner");
    string public constant Mansion =
        "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV";
    uint256 private testFractions = 100;

    function setUp() public {
        vm.prank(OWNER);
        marketNft = new MarketNft(0.01 ether);
    }

    function testMintAsOwner() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, testFractions);

        assertEq(marketNft.ownerOf(0), address(OWNER));
        assertEq(marketNft.balanceOf(OWNER), 1);
    }
}
