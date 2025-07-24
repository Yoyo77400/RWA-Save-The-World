// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { RealWorldAsset } from "./RealWorldAsset.sol";
import { RealWorldAssetToken } from "./RealWorldAssetToken.sol";

contract RealWorldAssetManager is Initializable, OwnableUpgradeable {
    RealWorldAsset private _asset;
    RealWorldAssetToken private _assetToken;
    uint256 private pricePerToken;

    event AssetTokenUpdated(address indexed assetTokenAddress);
    event AssetOwnershipTransferred(address indexed newOwner);
    event Bought(address indexed buyer, uint256 amount, uint256 totalPrice);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();

    address public asset;
    address public assetToken;


    function initialize(
        address asset_,
        address assetToken_,
        uint256 pricePerToken_,
        address owner_
    ) public initializer {
        __Ownable_init(owner_);
        asset = asset_;
        assetToken = assetToken_;
        pricePerToken = pricePerToken_;

        _asset = RealWorldAsset(asset_);
        _assetToken = RealWorldAssetToken(assetToken_);
    }


    function updateAssetToken(address newAssetTokenAddress) external onlyOwner {
        if (newAssetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        _assetToken = RealWorldAssetToken(newAssetTokenAddress);
        emit AssetTokenUpdated(newAssetTokenAddress);
    }

    function getAsset() public view returns (RealWorldAsset) {
        return _asset;
    }

    function getAssetToken() public view returns (RealWorldAssetToken) {
        return _assetToken;
    }

    function buyAssetToken(uint256 amount) external payable {
        if (amount == 0) revert InvalidAmount();
        if (address(_assetToken) == address(0)) revert AssetNotFound();
        uint256 requiredPrice = amount * pricePerToken;
        if (msg.value < requiredPrice) revert InvalidPrice();
        if (_assetToken.totalSupply() + amount > _assetToken.limitSupply()) revert LimitExceeded();

        _assetToken.transfer(msg.sender, amount);
        (bool sent, ) = payable(owner()).call{value: requiredPrice}("");
        require(sent, "Transfer failed");

        emit Bought(msg.sender, amount, requiredPrice);
    }

    function sellAssetToken(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (address(_assetToken) == address(0)) revert AssetNotFound();

        _assetToken.transferFrom(msg.sender, address(this), amount);
        _assetToken.burn(amount);

        uint256 refund = amount * pricePerToken;
        (bool sent, ) = payable(msg.sender).call{value: refund}("");
        require(sent, "Refund failed");
    }

    function getPricePerToken() external view returns (uint256) {
        return pricePerToken;
    }

    function setDependencies(address assetAddr, address tokenAddr) external onlyOwner {
        _asset = RealWorldAsset(assetAddr);
        _assetToken = RealWorldAssetToken(tokenAddr);

        asset = assetAddr;             
        assetToken = tokenAddr;         
    }


}
