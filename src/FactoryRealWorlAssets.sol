// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { RealWorldAsset } from "./RealWorldAsset.sol";

contract FactoryRealWorldAssets {
    // State variables
    RealWorldAsset[] private _assets;
    mapping(bytes32 => bool) private _existingAsset;

    // Events and errors
    event AssetCreated(address indexed assetAddress, string name, string symbol);
    error EmptyName();
    error EmptySymbol();
    error AssetAlreadyExists();
    error AssetNotFound();

    function createAsset(string memory name, string memory symbol) external returns (RealWorldAsset) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();
        if (_existingAsset[nameHash]) revert AssetAlreadyExists();
        
        // Create a new RealWorldAsset instance. Add it to the assets array and mark it as existing.
        RealWorldAsset asset = new RealWorldAsset(name, symbol);
        _existingAsset[nameHash] = true;
        _assets.push(asset);
        emit AssetCreated(address(asset), name, symbol);
        return asset;
    }

    function getAssets() external view returns (RealWorldAsset[] memory) {
        return _assets;
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