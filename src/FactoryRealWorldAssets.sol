// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { RealWorldAsset } from "./RealWorldAsset.sol";
import { RealWorldAssetToken } from "./RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "./RealWorldAssetManager.sol";

contract FactoryRealWorldAssets {
    
    RealWorldAsset[] private _assets;
    mapping(bytes32 => bool) private _existingAsset;
    mapping(address => bool) private _isAssets;
    mapping(address => Assets) private _assetDetails;
    struct Assets {
        address assetAddress;
        address assetTokenAddress;
        address assetManagerAddress;
        address owner;
    }
    
    event AssetCreated(address indexed assetAddress, string name, string symbol);
    error EmptyName();
    error EmptySymbol();
    error AssetAlreadyExists();
    error AssetNotFound();

    function createAsset(string memory name, string memory symbol, address _owner) external returns (RealWorldAsset) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();
        if (_existingAsset[nameHash]) revert AssetAlreadyExists();
        
        RealWorldAsset asset = new RealWorldAsset(name, symbol, _owner);
        RealWorldAssetToken assetToken = new RealWorldAssetToken(name, symbol, 1000000 * 10 ** 18, _owner);
        RealWorldAssetManager assetManager = new RealWorldAssetManager(address(asset), address(assetToken), 1, _owner);
        _assetDetails[address(asset)] = Assets({
            assetAddress: address(asset),
            assetTokenAddress: address(assetToken),
            assetManagerAddress: address(assetManager),
            owner: _owner
        });
        _existingAsset[nameHash] = true;
        _isAssets[address(asset)] = true;
        _assets.push(asset);
        emit AssetCreated(address(asset), name, symbol);
        return asset;
    }

    function getAssets() external view returns (RealWorldAsset[] memory) {
        return _assets;
    }

    function getAssetToken(address assetAddress) external view returns (RealWorldAssetToken) {
        if (!_isAssets[assetAddress]) revert AssetNotFound();
        return RealWorldAssetToken(_assetDetails[assetAddress].assetTokenAddress);
    }

    function getAssetManager(address assetAddress) external view returns (RealWorldAssetManager) {
        if (!_isAssets[assetAddress]) revert AssetNotFound();
        return RealWorldAssetManager(_assetDetails[assetAddress].assetManagerAddress);
    }

    function getAssetCount() external view returns (uint256) {
        return _assets.length;
    }

    function getAssetByIndex(uint256 index) external view returns (RealWorldAsset) {
        if (index >= _assets.length) {
            revert AssetNotFound();
        }
        return _assets[index];
    }

    function getDeployedAssetsAddresses() external view returns (address[] memory) {
        address[] memory addresses = new address[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            addresses[i] = address(_assets[i]);
        }
        return addresses;
    }
}