// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FactoryRealWorldAssets } from "./FactoryRealWorlAssets.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MarketPlace is Ownable {
    
    uint16 private _feePercentage;
    address private _feeRecipient;
    FactoryRealWorldAssets private _factory;

    enum SaleStatus { Active, Inactive }
    enum SaleType { FixedPrice, Auction }
    struct Sale {
        address assetAddress;
        address seller;
        SaleType saleType;
        uint256 price; // For FixedPrice
        uint256 auctionEndTime; // For Auction
        uint256 assetId;
        uint256 highestBid;
        address highestBidder;
        bool active;
    }

    mapping(uint256 => Sale) private _sales;
    mapping(address => mapping(uint256 => uint256)) private _assetSales; // assetAddress -> assetId -> saleId
    uint256 private _saleCounter;

    event Listed(uint256 indexed saleId, address indexed assetAddress, address indexed seller, SaleType saleType, uint256 price);
    event SaleStatusChanged(uint256 indexed saleId, SaleStatus status);
    event Purchased(uint256 indexed saleId, address indexed buyer, uint256 price);
    event BidPlaced(uint256 indexed saleId, address indexed bidder, uint256 bidAmount);
    event AuctionEnded(uint256 indexed saleId, address indexed winner, uint256 winningBid);
    event ListingRemoved(uint256 indexed saleId);

    error SaleNotFound();
    error InvalidSaleStatus();
    error InvalidSaleType();
    error InvalidPrice();
    error AuctionNotActive();
    error AuctionAlreadyEnded();
    error NotHighestBidder();
    error NotAssetOwner();
    error SaleAlreadyActive();
    error SaleAlreadyInactive();
    error InvalidFeePercentage();
    error InvalidFeeRecipient();


    constructor(address factoryAddress, address feeRecipient, uint16 feePercentage) Ownable(msg.sender) {
        _factory = FactoryRealWorldAssets(factoryAddress);
        _feeRecipient = feeRecipient;
        _feePercentage = feePercentage;
        if (feeRecipient == address(0)) revert InvalidFeeRecipient();
        if (feePercentage > 10) revert InvalidFeePercentage();
    }

    function listAssetFixedPrice(
        address assetAddress,
        uint256 assetId,
        SaleType saleType,
        uint256 price
    ) external returns (uint256) {
        if (assetAddress == address(0)) revert InvalidSaleType();
        if (_isAssetListed(assetAddress, assetId)) revert SaleAlreadyActive();
        if (saleType == SaleType.FixedPrice && price <= 0) revert InvalidPrice();
        _saleCounter++;
        Sale storage sale = _sales[_saleCounter];
        sale.assetAddress = assetAddress;
        sale.seller = msg.sender;
        sale.saleType = saleType;
        sale.price = price;
        sale.assetId = assetId;
        sale.active = true;
        _assetSales[assetAddress][assetId] = _saleCounter;

        emit Listed(_saleCounter, assetAddress, msg.sender, saleType, price);
        return _saleCounter;
    }

    function listAssetAuction(
        address assetAddress,
        uint256 assetId,
        SaleType saleType,
        uint256 startingPrice,
        uint256 auctionDurationHours
    ) external returns (uint256) {
        if (assetAddress == address(0)) revert InvalidSaleType();
        if (_isAssetListed(assetAddress, assetId)) revert SaleAlreadyActive();
        if (saleType != SaleType.Auction || startingPrice <= 0 || auctionDurationHours <= 0) revert InvalidPrice();
        
        
        _saleCounter++;
        Sale storage sale = _sales[_saleCounter];
        sale.assetAddress = assetAddress;
        sale.seller = msg.sender;
        sale.saleType = saleType;
        sale.price = startingPrice;
        sale.auctionEndTime = block.timestamp + auctionDurationHours * 1 hours;
        sale.assetId = assetId;
        sale.active = true;
        _assetSales[assetAddress][assetId] = _saleCounter;

        emit Listed(_saleCounter, assetAddress, msg.sender, saleType, startingPrice);
        return _saleCounter;
    }

    function _isAssetListed(address assetAddress, uint256 assetId) internal view returns (bool) {
        return _assetSales[assetAddress][assetId] != 0;
    }

    function purchaseAsset(uint256 saleId) external payable {
        Sale storage sale = _sales[saleId];
        if (saleId == 0 || sale.assetAddress == address(0)) revert SaleNotFound();
        if (!sale.active) revert InvalidSaleStatus();
        if (sale.saleType != SaleType.FixedPrice) revert InvalidSaleType();
        if (msg.value < sale.price) revert InvalidPrice();

        IERC721(sale.assetAddress).transferFrom(sale.seller, msg.sender, sale.assetId);
        
        // Calculate fee and transfer to fee recipient
        uint256 fee = (sale.price * _feePercentage) / 100;
        payable(_feeRecipient).transfer(fee);
        
        // Transfer remaining amount to seller
        payable(sale.seller).transfer(sale.price - fee);

        sale.active = false;
        emit Purchased(saleId, msg.sender, sale.price);
    }

}