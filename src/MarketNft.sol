// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarketNft is ERC721 {
    uint256 private s_tokenCounter;
    uint256 private i_maxSupply = 100;
    uint256 private i_price = 0.1 ether;

    mapping(uint256 => string) private s_tokenIdToUri;

    constructor(uint256 maxSupply, uint256 price) ERC721("Example", "EX") {
        s_tokenCounter = 0;
        i_maxSupply = maxSupply;
        i_price = price;
    }

    function mintNft(string memory tokenUri) public payable {
        require(msg.value >= i_price, "Insufficient payment");
        require(s_tokenCounter < i_maxSupply, "Max supply reached");
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }

    function getTotalSupply() public view returns (uint256) {
        return i_maxSupply;
    }

    function getRemainingSupply() public view returns (uint256) {
        return i_maxSupply - s_tokenCounter;
    }

    function getPrice() public view returns (uint256) {
        return i_price;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    //transfer(address to, uint256 value): Transfers a specified amount of tokens from the sender to the to address (could be a smart contract).
    function transfer(address to, uint256 value) public {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        require(to.code.length == 0, "Cannot send to a contract");
        safeTransferFrom(msg.sender, to, value);
    }

    //approve(address spender, uint256 tokenId): Allows a spender (e.g., the smart contract) to withdraw tokens from your address up to the approved value.
    function approve(address spender, uint256 tokenId) public override {
        require(spender.code.length == 0, "Cannot approve a contract");
        super.approve(spender, tokenId);
    }

    //transferFrom(address from, address to, uint256 value): Allows a spender (previously approved) to transfer tokens from one address to another.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override {
        require(balanceOf(from) >= value, "Insufficient balance");
        require(to.code.length == 0, "Cannot send to a contract");
        super.transferFrom(from, to, value);
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
