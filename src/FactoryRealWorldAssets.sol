// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { RealWorldAsset } from "./RealWorldAsset.sol";
import { RealWorldAssetToken } from "./RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "./RealWorldAssetManager.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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

    struct AssetParams {
        RealWorldAsset asset;
        RealWorldAssetToken assetToken;
        RealWorldAssetManager assetManager;
        address owner;
        bytes32 nameHash;
        string name;
        string symbol;
    }

    event AssetCreated(address indexed assetAddress, string name, string symbol);
    error EmptyName();
    error EmptySymbol();
    error AssetAlreadyExists();
    error AssetNotFound();

    function createAsset(string memory name, string memory symbol, address _owner) external returns (RealWorldAsset) {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        if (_existingAsset[nameHash]) revert AssetAlreadyExists();

        (RealWorldAsset asset, RealWorldAssetToken assetToken, RealWorldAssetManager assetManager) =
            _deployLogicAndProxies(name, symbol, _owner);

        _registerAsset(AssetParams({
            asset: asset,
            assetToken: assetToken,
            assetManager: assetManager,
            owner: _owner,
            nameHash: nameHash,
            name: name,
            symbol: symbol
        }));


        return asset;
    }

    function _deployLogicAndProxies(
        string memory name,
        string memory symbol,
        address _owner
    ) internal returns (RealWorldAsset, RealWorldAssetToken, RealWorldAssetManager) {
        RealWorldAsset assetImpl = new RealWorldAsset();
        RealWorldAssetToken tokenImpl = new RealWorldAssetToken();
        RealWorldAssetManager managerImpl = new RealWorldAssetManager();

        bytes memory assetInit = abi.encodeWithSelector(
            RealWorldAsset.initialize.selector,
            name,
            symbol,
            _owner
        );
        ERC1967Proxy assetProxy = new ERC1967Proxy(address(assetImpl), assetInit);

        bytes memory tokenInit = abi.encodeWithSelector(
            RealWorldAssetToken.initialize.selector,
            name,
            symbol,
            1000000 * 10 ** 18,
            _owner
        );
        ERC1967Proxy tokenProxy = new ERC1967Proxy(address(tokenImpl), tokenInit);

        bytes memory managerInit = abi.encodeWithSelector(
            RealWorldAssetManager.initialize.selector,
            address(assetProxy),
            address(tokenProxy),
            1,
            _owner
        );
        ERC1967Proxy managerProxy = new ERC1967Proxy(address(managerImpl), managerInit);

        return (
            RealWorldAsset(address(assetProxy)),
            RealWorldAssetToken(address(tokenProxy)),
            RealWorldAssetManager(address(managerProxy))
        );
    }

    function _registerAsset(AssetParams memory p) internal {
        _assetDetails[address(p.asset)] = Assets({
            assetAddress: address(p.asset),
            assetTokenAddress: address(p.assetToken),
            assetManagerAddress: address(p.assetManager),
            owner: p.owner
        });

        _existingAsset[p.nameHash] = true;
        _isAssets[address(p.asset)] = true;
        _assets.push(p.asset);

        emit AssetCreated(address(p.asset), p.name, p.symbol);
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
        if (index >= _assets.length) revert AssetNotFound();
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
