// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { RealWorldAsset } from "./RealWorldAsset.sol";

contract FactoryRealWorldAssets {
    RealWorldAsset[] private _assets;

    event AssetCreated(address indexed assetAddress, string name, string symbol);
    error EmptyName();
    error EmptySymbol();
    error AssetAlreadyExists();
    error AssetNotFound();

    function createAsset(string memory name, string memory symbol) external returns (RealWorldAsset) {
        require(bytes(name).length > 0, EmptyName());
        require(bytes(symbol).length > 0, EmptySymbol());
        // Create a new RealWorldAsset instance
        // and add it to the list of assets
        // Ensure the asset does not already exist
        for (uint256 i = 0; i < _assets.length; i++) {
            require(
                keccak256(abi.encodePacked(_assets[i].getName())) != keccak256(abi.encodePacked(name)),
                AssetAlreadyExists()
            );
        }
        RealWorldAsset asset = new RealWorldAsset(name, symbol);
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