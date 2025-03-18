// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
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

    error MarketNFT__NotOwner();
    error MarketNFT__InsufficientPayment();
    error MarketNFT__InsufficientSupply();
    error MarketNFT__InsufficientBalance();
    error MarketNFT__NonExistentNft();
    error MarketNFT__TransferFailed();

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
        vm.expectRevert(MarketNFT__NotOwner.selector);
        marketNft.mintNft(Mansion, testFractions);
    }

    function testBuyFraction() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNFT__InsufficientPayment.selector);
        marketNft.buyFraction(0, 10);
    }

    function testBuyFractionInsufficientPayment() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNFT__InsufficientPayment.selector);
        marketNft.buyFraction{value: 0.05 ether}(0, 10);
    }

    function testBuyFractionInsufficientSupply() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        uint256 pricePerFraction = marketNft.getPrice();
        uint256 totalCost = pricePerFraction * 101;

        vm.deal(NOT_OWNER, totalCost);

        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNft.MarketNFT__InsufficientSupply.selector);
        marketNft.buyFraction{value: totalCost}(0, 101);
    }

    function testBuyFractionUpdatesBalances() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 0.1 ether);

        vm.prank(NOT_OWNER);
        marketNft.buyFraction{value: 0.1 ether}(0, 10);

        assertEq(marketNft.s_fractionalBalance(0, NOT_OWNER), 10);
        assertEq(marketNft.s_fractionalBalance(0, address(marketNft)), 90);
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
        assertEq(marketNft.s_fractionalBalance(0, address(marketNft)), 90);
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

        assertEq(marketNft.s_fractionalBalance(0, address(marketNft)), 100);
        assertEq(marketNft.s_fractionalBalance(1, address(marketNft)), 50);
        assertEq(marketNft.s_fractionalBalance(2, address(marketNft)), 200);
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
        vm.expectRevert(MarketNft.MarketNFT__PropertyDoesNotExist.selector);
        marketNft.buyFraction{value: 0.1 ether}(999, 10);
        assertEq(marketNft.s_fractionalBalance(999, NOT_OWNER), 0);
    }

    function testCantSellToNonExistentProperty() public {
        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNft.MarketNFT__PropertyDoesNotExist.selector);
        marketNft.sellFraction(999, 10);
        assertEq(marketNft.s_fractionalBalance(999, address(marketNft)), 0);
    }

    function testWithdrawEmptyBalance() public {
        assertEq(address(marketNft).balance, 0);

        vm.prank(OWNER);
        marketNft.withdraw();
        assertEq(address(marketNft).balance, 0);
    }

    function testWithdrawAsNonOwner() public {
        vm.deal(address(marketNft), 1 ether);

        vm.prank(NOT_OWNER);
        vm.expectRevert(MarketNFT__NotOwner.selector);
        marketNft.withdraw();
        assertEq(address(marketNft).balance, 1 ether);
    }

    function testSetFractionPrice() public {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit MarketNft.FractionPriceUpdated(NewPrice);
        marketNft.setNewFractionPrice(NewPrice);

        assertEq(marketNft.getPrice(), NewPrice);

        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.deal(NOT_OWNER, 1 ether);
        vm.prank(NOT_OWNER);
        marketNft.buyFraction{value: 0.2 ether}(0, 10);

        assertEq(marketNft.s_fractionalBalance(0, NOT_OWNER), 10);
    }

    function testSetTokenMetadata() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            0,
            "Mansion",
            "A mansion",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );

        string memory tokenURI = marketNft.tokenURI(0);
        console.log(tokenURI);
    }

    function testSetTokenMetadataAsNonOwner() public {
        vm.prank(OWNER);
        marketNft.mintNft(
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV",
            100
        );

        address notOwner = 0x294A67e30833690E0c6413E59CAc1543790BE3A7;
        vm.prank(notOwner);

        vm.expectRevert(MarketNFT__NotOwner.selector);
        marketNft.setTokenMetadata(
            0,
            "New Name",
            "New Description",
            "New Location",
            "New Image"
        );
        string memory tokenURI = marketNft.tokenURI(0);
        console.log(tokenURI);
    }

    function testTokenURI() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            0,
            "Ploppertje",
            "A plophuisje",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );
        string memory tokenURI = marketNft.tokenURI(0);
        console.log(tokenURI);
    }

    function testTokenURIWithCustomName() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            0,
            "Ploppertje",
            "A plophuisje",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );
        string memory tokenURI = marketNft.tokenURI(0);
        console.log(tokenURI);
    }

    function testTokenURIWithCustomDescription() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            0,
            "Ploppertje",
            "A plophuisje",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );
        string memory tokenURI = marketNft.tokenURI(0);
        console.log(tokenURI);
    }

    function testCreateNftWithCustomImage() public {
        vm.prank(OWNER);
        marketNft.mintNft(
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV",
            100
        );

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            0,
            "Mansion",
            "A mansion",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );

        vm.prank(OWNER);
        string memory tokenURI = marketNft.tokenURI(0);
        assertTrue(bytes(tokenURI).length > 0, "Token URI should not be empty");
    }

    function testNewNftWithCustomMetadata() public {
        vm.prank(OWNER);
        marketNft.mintNft(Mansion, 100);
        uint256 tokenId = 0;

        assertTrue(
            marketNft.ownerOf(tokenId) == OWNER,
            "Owner should be correct"
        );
        string memory initialTokenURI = marketNft.tokenURI(tokenId);

        vm.prank(OWNER);
        marketNft.setTokenMetadata(
            tokenId,
            "Mansion",
            "A mansion",
            "New York",
            "ipfs://QmQJkXJGvn1Qe1NyVzDYdffAQTiecVUaPeej8KBWVaeyfV"
        );

        vm.prank(OWNER);
        string memory updatedTokenURI = marketNft.tokenURI(tokenId);

        assertTrue(
            bytes(updatedTokenURI).length > 0,
            "Token URI should not be empty"
        );
        assertTrue(
            keccak256(abi.encodePacked(initialTokenURI)) !=
                keccak256(abi.encodePacked(updatedTokenURI)),
            "Token URI should change after metadata update"
        );
    }
}
