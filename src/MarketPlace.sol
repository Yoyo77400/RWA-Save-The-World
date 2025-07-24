// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { FactoryRealWorldAssets } from "./FactoryRealWorldAssets.sol";
import { IERC721 } from "@openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MarketPlace is Initializable, OwnableUpgradeable {
    uint16 private _feePercentage;
    address private _feeRecipient;
    FactoryRealWorldAssets private _factory;

    enum SaleStatus { Active, Inactive }
    enum SaleType { FixedPrice, Auction }

    struct Sale {
        address assetAddress;
        address seller;
        SaleType saleType;
        uint256 price;
        uint256 auctionEndTime;
        uint256 assetId;
        uint256 highestBid;
        address highestBidder;
        bool active;
    }

    mapping(uint256 => Sale) private _sales;
    mapping(address => mapping(uint256 => uint256)) private _assetSales;
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

    /// @notice Appelée à la place du constructeur pour initialiser le contrat
    function initialize(address factoryAddress, address feeRecipient, uint16 feePercentage) public initializer {
        __Ownable_init(msg.sender);
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
        delete _assetSales[sale.assetAddress][sale.assetId];
        emit Purchased(saleId, msg.sender, sale.price);
    }

    function placeBid(uint256 saleId, uint256 value) external payable {
        Sale storage sale = _sales[saleId];
        if (saleId == 0 || sale.assetAddress == address(0)) revert SaleNotFound();
        if (!sale.active || sale.saleType != SaleType.Auction) revert InvalidSaleStatus();
        if (block.timestamp >= sale.auctionEndTime) revert AuctionAlreadyEnded();
        if (msg.value <= sale.highestBid) revert InvalidPrice();

        if (sale.highestBidder != address(0)) {
            payable(sale.highestBidder).transfer(sale.highestBid);
        }

        sale.highestBid = value;
        sale.highestBidder = msg.sender;

        emit BidPlaced(saleId, msg.sender, value);
    }

    function endAuction(uint256 saleId) external {
        Sale storage sale = _sales[saleId];
        if (saleId == 0 || sale.assetAddress == address(0)) revert SaleNotFound();
        if (!sale.active || sale.saleType != SaleType.Auction) revert InvalidSaleStatus();
        if (block.timestamp > sale.auctionEndTime) revert AuctionNotActive();

        if (sale.highestBidder != address(0) && sale.highestBid > 0) {
            IERC721(sale.assetAddress).transferFrom(address(this), sale.highestBidder, sale.assetId);
            payable(sale.seller).transfer(sale.highestBid);
            emit AuctionEnded(saleId, sale.highestBidder, sale.highestBid);
        } else {
            IERC721(sale.assetAddress).transferFrom(address(this), sale.seller, sale.assetId);
        }

        sale.active = false;
        delete _assetSales[sale.assetAddress][sale.assetId];
    }

    function removeListing(uint256 saleId) external {
        Sale storage sale = _sales[saleId];
        if (saleId == 0 || sale.assetAddress == address(0)) revert SaleNotFound();
        if (!sale.active) revert InvalidSaleStatus();
        if (sale.seller != msg.sender) revert NotAssetOwner();

        sale.active = false;
        delete _assetSales[sale.assetAddress][sale.assetId];
        emit ListingRemoved(saleId);
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        if (newFeeRecipient == address(0)) revert InvalidFeeRecipient();
        _feeRecipient = newFeeRecipient;
    }

    function setFeePercentage(uint16 newFeePercentage) external onlyOwner {
        if (newFeePercentage > 10) revert InvalidFeePercentage();
        _feePercentage = newFeePercentage;
    }

    function getFactory() public view returns (address) {
        return address(_factory);
    }

    function getSale(uint256 saleId) public view returns (Sale memory) {
        Sale storage sale = _sales[saleId];
        if (saleId == 0 || sale.assetAddress == address(0)) revert SaleNotFound();
        return sale;
    }

    function getSales() public view returns (Sale[] memory) {
        Sale[] memory sales = new Sale[](_saleCounter);
        for (uint256 i = 1; i <= _saleCounter; i++) {
            sales[i - 1] = _sales[i];
        }
        return sales;
    }
}