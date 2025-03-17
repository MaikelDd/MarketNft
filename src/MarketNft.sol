// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MarketNft is ERC721 {
    uint256 private s_tokenCounter;
    uint256 private s_fractionPrice = 0.01 ether;
    address private immutable i_owner;

    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(uint256 => uint256) public s_fractionalSupply;
    mapping(uint256 => mapping(address => uint256)) public s_fractionalBalance;
    mapping(uint256 => bool) private s_tokenIdExists;

    event FractionPriceUpdated(uint256 newPrice);
    event Withdraw(address indexed owner, uint256 amount);

    constructor(uint256 price) ERC721("Example", "EX") {
        s_tokenCounter = 0;
        s_fractionPrice = price;
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not the owner");
        _;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return s_tokenIdExists[tokenId];
    }

    function mintNft(
        string memory tokenUri,
        uint256 fractions
    ) public onlyOwner {
        uint256 newTokenId = s_tokenCounter;
        s_tokenIdToUri[newTokenId] = tokenUri;
        _safeMint(msg.sender, newTokenId);

        s_fractionalSupply[newTokenId] = fractions;
        s_fractionalBalance[newTokenId][address(this)] = fractions;

        s_tokenCounter++;
    }

    function buyFraction(uint256 tokenId, uint256 amount) public payable {
        require(msg.value >= s_fractionPrice, "Insufficient payment");
        require(
            s_fractionalBalance[tokenId][i_owner] >= amount,
            "Insufficient supply"
        );
        require(tokenExists(tokenId), "Token does not exist");

        s_fractionalBalance[tokenId][i_owner] -= amount;
        s_fractionalBalance[tokenId][msg.sender] += amount;
    }

    function sellFraction(uint256 tokenId, uint256 amount) public payable {
        require(
            s_fractionalBalance[tokenId][msg.sender] >= amount,
            "Insufficient balance"
        );
        require(tokenExists(tokenId), "Token does not exist");

        require(
            address(this).balance >= s_fractionPrice * amount,
            "Insufficient balance"
        );

        s_fractionalBalance[tokenId][msg.sender] -= amount;
        s_fractionalBalance[tokenId][i_owner] += amount;

        uint256 payment = s_fractionPrice * amount;
        (bool success, ) = payable(msg.sender).call{value: payment}("");
        require(success, "Transfer failed");
    }

    function setNewFractionPrice(uint256 newPrice) public onlyOwner {
        s_fractionPrice = newPrice;
        emit FractionPriceUpdated(newPrice);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }

    function getPrice() public view returns (uint256) {
        return s_fractionPrice;
    }

    // fallback
    fallback() external payable {
        revert("Fallback");
    }

    // receive
    receive() external payable {
        revert("Fallback");
    }
}
