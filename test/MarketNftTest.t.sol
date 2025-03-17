// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MarketNft} from "../src/MarketNft.sol";
import {DeployMarketNft} from "../script/DeployMarketNft.s.sol";

contract MarketNftTest is Test {
    MarketNft public marketNft;
    DeployMarketNft public deployer;
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    string public constant Mansion =
        "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV";
    string public constant Beach = "ipfs://QmBeach";

    function setUp() public {
        deployer = new DeployMarketNft();
        marketNft = deployer.run();
    }

    function testSupplyIsCorrect() public view {
        uint256 expectedSupply = 100;
        uint256 actualSupply = marketNft.getTotalSupply();
        assertEq(actualSupply, expectedSupply);
    }

    function testPriceIsCorrect() public view {
        uint256 expectedPrice = 0.1 ether;
        uint256 actualPrice = marketNft.getPrice();
        assertEq(actualPrice, expectedPrice);
    }

    function testMintNft() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
        assert(marketNft.balanceOf(USER) == 1);
        assert(
            keccak256(abi.encodePacked(Mansion)) ==
                keccak256(abi.encodePacked(marketNft.tokenURI(0)))
        );
    }

    function testMintNftInsufficientPayment() public {
        vm.deal(USER, 0.05 ether);
        vm.prank(USER);
        vm.expectRevert("Insufficient payment");
        marketNft.mintNft{value: 0.05 ether}(Mansion);
    }

    function testMultipleMints() public {
        vm.deal(USER, 0.4 ether);
        vm.startPrank(USER);

        marketNft.mintNft{value: 0.1 ether}(Mansion);
        marketNft.mintNft{value: 0.1 ether}(Beach);

        assert(marketNft.balanceOf(USER) == 2);
        assert(
            keccak256(abi.encodePacked(Mansion)) ==
                keccak256(abi.encodePacked(marketNft.tokenURI(0)))
        );
        assert(
            keccak256(abi.encodePacked(Beach)) ==
                keccak256(abi.encodePacked(marketNft.tokenURI(1)))
        );
        vm.stopPrank();
    }

    function testRemainingSupply() public {
        uint256 initialSupply = marketNft.getRemainingSupply();
        assertEq(initialSupply, 100);

        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);

        uint256 remainingSupply = marketNft.getRemainingSupply();
        assertEq(remainingSupply, 99);
    }

    function testWithdraw() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
    }

    function testWithdrawFailsIfNotOwner() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
    }

    function testWithdrawFailsIfNotEnoughBalance() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
    }

    //fallback test
    function testFallback() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
    }

    function testReceive() public {
        vm.deal(USER, 0.1 ether);
        vm.prank(USER);
        marketNft.mintNft{value: 0.1 ether}(Mansion);
    }
}
