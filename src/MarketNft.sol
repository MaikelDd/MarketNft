// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MarketNft is ERC721 {
    uint256 private s_tokenCounter;
    uint256 private s_fractionPrice = 0.01 ether;
    address private immutable i_owner;

    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(uint256 => uint256) public s_fractionalSupply;
    mapping(uint256 => mapping(address => uint256)) public s_fractionalBalance;

    // metadata klaarzetten
    mapping(uint256 => TokenMetadata) public s_tokenMetadata;

    event FractionPriceUpdated(uint256 newPrice);
    event Withdraw(address indexed owner, uint256 amount);
    event BuyFraction(address indexed buyer, uint256 tokenId, uint256 amount);
    event SellFraction(address indexed seller, uint256 tokenId, uint256 amount);

    error MarketNFT__PropertyDoesNotExist();
    error MarketNFT__NotOwner();
    error MarketNFT__InsufficientPayment();
    error MarketNFT__InsufficientSupply();
    error MarketNFT__InsufficientBalance();
    error MarketNFT__TransferFailed();
    error MarketNFT__NotEnoughBalance();
    error MarketNFT__InsufficientFraction();

    constructor(uint256 price) ERC721("Example", "EX") {
        s_tokenCounter = 0;
        s_fractionPrice = price;
        i_owner = msg.sender;
    }

    // metadata struct
    struct TokenMetadata {
        string name;
        string description;
        string location;
        string image;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert MarketNFT__NotOwner();
        }
        _;
    }

    modifier exists(uint256 tokenId) {
        if (s_fractionalSupply[tokenId] == 0) {
            revert MarketNFT__PropertyDoesNotExist();
        }
        _;
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

    function buyFraction(
        uint256 tokenId,
        uint256 amount
    ) public payable exists(tokenId) {
        if (msg.value < s_fractionPrice * amount) {
            revert MarketNFT__InsufficientPayment();
        }
        if (s_fractionalBalance[tokenId][address(this)] < amount) {
            revert MarketNFT__InsufficientSupply();
        }

        s_fractionalBalance[tokenId][address(this)] -= amount;
        s_fractionalBalance[tokenId][msg.sender] += amount;
        emit BuyFraction(msg.sender, tokenId, amount);
    }

    function sellFraction(
        uint256 tokenId,
        uint256 amount
    ) public payable exists(tokenId) {
        if (s_fractionalBalance[tokenId][msg.sender] < amount) {
            revert MarketNFT__InsufficientFraction();
        }

        if (address(this).balance < s_fractionPrice * amount) {
            revert MarketNFT__InsufficientBalance();
        }

        s_fractionalBalance[tokenId][msg.sender] -= amount;
        s_fractionalBalance[tokenId][address(this)] += amount;

        uint256 payment = s_fractionPrice * amount;
        (bool success, ) = payable(msg.sender).call{value: payment}("");
        if (!success) {
            revert MarketNFT__TransferFailed();
        }
        emit SellFraction(msg.sender, tokenId, amount);
    }

    function setNewFractionPrice(uint256 newPrice) public onlyOwner {
        s_fractionPrice = newPrice;
        emit FractionPriceUpdated(newPrice);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert MarketNFT__TransferFailed();
        }
        emit Withdraw(msg.sender, balance);
    }

    function setTokenMetadata(
        uint256 tokenId,
        string memory _name,
        string memory _description,
        string memory _location,
        string memory _image
    ) public {
        if (ownerOf(tokenId) != msg.sender) {
            revert MarketNFT__NotOwner();
        }

        s_tokenMetadata[tokenId] = TokenMetadata({
            name: _name,
            description: _description,
            location: _location,
            image: _image
        });
    }

    function tokenURI(
        uint256 tokenId
    ) public view override exists(tokenId) returns (string memory) {
        TokenMetadata memory metadata = s_tokenMetadata[tokenId];
        string memory imageURI = bytes(metadata.image).length > 0
            ? metadata.image
            : s_tokenIdToUri[tokenId];

        // Get the name (custom or contract default)
        string memory tokenName = bytes(metadata.name).length > 0
            ? metadata.name
            : name();

        // Build the final JSON
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                tokenName,
                                '", "description": "',
                                metadata.description,
                                '", "location": "',
                                metadata.location,
                                '", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getPrice() public view returns (uint256) {
        return s_fractionPrice;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFractionalSupply(
        uint256 tokenId
    ) public view returns (uint256) {
        return s_fractionalSupply[tokenId];
    }

    function getFractionalBalance(
        uint256 tokenId,
        address
    ) public view returns (uint256) {
        return s_fractionalBalance[tokenId][address(this)];
    }

    function getTokenIdToUri(
        uint256 tokenId
    ) public view returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getOwner() public view returns (address) {
        return address(this);
    }

    fallback() external payable {
        revert("Fallback");
    }

    receive() external payable {
        revert("Fallback");
    }
}
