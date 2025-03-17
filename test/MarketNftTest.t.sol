// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MarketNft} from "../src/MarketNft.sol";
import {DeployMarketNft} from "../script/DeployMarketNft.s.sol";

contract MarketNftTest is Test {
    MarketNft public marketNft;
    DeployMarketNft public deployer;

    address public OWNER = makeAddr("owner");
    address public NOT_OWNER = makeAddr("notOwner");

    string public constant Villa = "ipfs://QmQJkXJGvn1Qe1NyVzD";
    string public constant Apartment = "ipfs://QmQJkXJG";
    string public constant Mansion =
        "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV";
    uint256 private testFractions = 100;

    uint256 constant Price = 0.01 ether;
    uint256 constant NewPrice = 0.02 ether;

    error PropertyNFT__NotOwner();
    error PropertyNFT__InsufficientPayment();
    error PropertyNFT__InsufficientSupply();
    error PropertyNFT__InsufficientBalance();
    error PropertyNFT__NonExistentNft();

    function setUp() public {
        vm.prank(OWNER);
        marketNft = new MarketNft(0.01 ether);

        // Fund the buyer with 0.1 ether
        vm.deal(NOT_OWNER, 0.1 ether);
    }

    function testMintAsOwner() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, testFractions);

        assertEq(marketNft.ownerOf(0), address(OWNER));
        assertEq(marketNft.balanceOf(OWNER), 1);
    }

    function testMintAsNotOwner() public {
        vm.prank(NOT_OWNER);
        vm.expectRevert(PropertyNFT__NotOwner.selector);
        marketNft.mintNft(Mansion, testFractions);
    }

    function testBuyFraction() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(NOT_OWNER);
        vm.expectRevert(PropertyNFT__InsufficientPayment.selector);
        marketNft.buyFraction(0, 10);
    }

    function testBuyFractionInsufficientPayment() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        vm.expectRevert(PropertyNFT__InsufficientPayment.selector);
        marketNft.buyFraction{value: 0.05 ether}(0, 10);
    }

    function testBuyFractionInsufficientSupply() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(NOT_OWNER);
        vm.expectRevert(PropertyNFT__InsufficientPayment.selector);
        marketNft.buyFraction(0, 101);
    }

    function testBuyFractionUpdatesBalances() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 0.1 ether);

        vm.prank(NOT_OWNER);
        marketNft.buyFraction{value: 0.1 ether}(0, 10);

        assertEq(marketNft.s_fractionalBalance(0, NOT_OWNER), 10);
        assertEq(marketNft.s_fractionalBalance(0, OWNER), 90);
        assertEq(address(marketNft).balance, 0.1 ether);
    }

    function testSellFraction() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 0.2 ether);
        vm.prank(NOT_OWNER);
        marketNft.buyFraction{value: 0.2 ether}(0, 20);

        vm.deal(address(marketNft), 0.1 ether);

        vm.prank(NOT_OWNER);
        marketNft.sellFraction(0, 10);
        assertEq(marketNft.s_fractionalBalance(0, NOT_OWNER), 10);
        assertEq(marketNft.s_fractionalBalance(0, OWNER), 90);
    }

    function testWithdraw() public {
        vm.deal(address(marketNft), 1 ether);

        uint256 ownerBalanceBefore = OWNER.balance;

        vm.prank(OWNER);
        marketNft.withdraw();

        assertEq(address(marketNft).balance, 0);
        assertEq(OWNER.balance, ownerBalanceBefore + 1 ether);
    }

    function testMintMultipleProperties() public {
        vm.startPrank(OWNER);
        marketNft.mintNft(Mansion, 100);
        marketNft.mintNft(Villa, 50);
        marketNft.mintNft(Apartment, 200);
        vm.stopPrank();

        assertEq(marketNft.s_fractionalSupply(0), 100);
        assertEq(marketNft.s_fractionalSupply(1), 50);
        assertEq(marketNft.s_fractionalSupply(2), 200);

        assertEq(marketNft.s_fractionalBalance(0, OWNER), 100);
        assertEq(marketNft.s_fractionalBalance(1, OWNER), 50);
        assertEq(marketNft.s_fractionalBalance(2, OWNER), 200);
    }

    function testFallbackAndReceive() public {
        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        (bool success, ) = address(marketNft).call{value: 0.1 ether}("");
        assertEq(success, false);

        vm.prank(NOT_OWNER);
        (success, ) = address(marketNft).call{value: 0.1 ether}(hex"12345678");
        assertEq(success, false);
    }

    function testCantBuyFromNonExistentProperty() public {
        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNft.PropertyNFT__PropertyDoesNotExist.selector);
        marketNft.buyFraction{value: 0.1 ether}(999, 10);
    }

    function testCantSellToNonExistentProperty() public {
        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNft.PropertyNFT__PropertyDoesNotExist.selector);
        marketNft.sellFraction(999, 10);
    }

    function testWithdrawEmptyBalance() public {
        assertEq(address(marketNft).balance, 0);

        vm.prank(OWNER);
        marketNft.withdraw();
    }

    function testWithdrawAsNonOwner() public {
        vm.deal(address(marketNft), 1 ether);

        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNft.PropertyNFT__NotOwner.selector);
        marketNft.withdraw();
    }

    function testSetFractionPrice() public {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit MarketNft.FractionPriceUpdated(NewPrice);
        marketNft.setNewFractionPrice(NewPrice);

        assertEq(marketNft.getPrice(), NewPrice);

        // Buy with new price
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        marketNft.buyFraction{value: 0.2 ether}(0, 10); // Now needs 0.2 ETH for 10 fractions

        assertEq(marketNft.s_fractionalBalance(0, NOT_OWNER), 10);
    }
}
