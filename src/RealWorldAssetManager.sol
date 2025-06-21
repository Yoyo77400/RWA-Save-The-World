// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { RealWorldAsset } from "./RealWorldAsset.sol";
import { RealWorldAssetToken } from "./RealWorldAssetToken.sol";
import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract RealWorldAssetManager is Ownable {
    RealWorldAsset private _asset;
    RealWorldAssetToken private _assetToken;
    uint256 pricePerToken;

    event AssetTokenUpdated(address indexed assetTokenAddress);
    event AssetOwnershipTransferred(address indexed newOwner);
    event Bought(address indexed buyer, uint256 amount, uint256 totalPrice);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();

    constructor(address assetAddress, address assetTokenAddress, uint256 pricePerToken_, address owner_) Ownable(msg.sender) {
        if (assetAddress == address(0)) revert InvalidAssetAddress();
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();

        _asset = RealWorldAsset(assetAddress);
        _assetToken = RealWorldAssetToken(assetTokenAddress);
        pricePerToken = pricePerToken_;
        _transferOwnership(owner_);
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

        _assetToken.transferFrom(owner(), msg.sender, amount);
        (bool sent, ) = payable(owner()).call{value: requiredPrice}("");
        require(sent, "Transfer failed");
        emit Bought(msg.sender, amount, requiredPrice);
    }

    function sellAssetToken(uint256 amount) external {
        if(amount == 0) revert InvalidAmount();
        if(address(_assetToken) == address(0)) revert AssetNotFound();

        _assetToken.burn(amount);
        payable(owner()).transfer(amount * pricePerToken);
    }

    function getPricePerToken() external view returns (uint256) {
        return pricePerToken;
    }

}