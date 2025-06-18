// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { FactoryRealWorldAssets } from "../src/FactoryRealWorldAssets.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";

contract FactoryRealWorldAssetsTest is Test {
    address private admin;
    FactoryRealWorldAssets private factory;

    function setUp() public {
        admin = address(0x1);
        vm.startPrank(admin);
            factory = new FactoryRealWorldAssets();
        vm.stopPrank();
    }

    function testCreateAsset() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";
        RealWorldAsset asset = factory.createAsset(name, symbol, admin);

        assertEq(asset.getName(), name);
        assertEq(asset.symbol(), symbol);
        assertEq(address(asset), address(factory.getAssets()[0]));
    }

    function testCreateAssetWithEmptyName() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptyName.selector));
        factory.createAsset("", "TAST", admin);
    }

    function testCreateAssetWithEmptySymbol() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptySymbol.selector));
        factory.createAsset("Test Asset", "", admin);
    }

    function testCreateDuplicateAsset() public {
        factory.createAsset("Test Asset", "TAST", admin);
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetAlreadyExists.selector));
        factory.createAsset("Test Asset", "TAST", admin);
    }

    function testGetAssets() public {
        factory.createAsset("Asset 1", "A1", admin);
        factory.createAsset("Asset 2", "A2", admin);

        RealWorldAsset[] memory assets = factory.getAssets();
        assertEq(assets.length, 2);
        assertEq(assets[0].getName(), "Asset 1");
        assertEq(assets[1].getName(), "Asset 2");
    }

    function testGetAssetCount() public {
        factory.createAsset("Asset 1", "A1", admin);
        factory.createAsset("Asset 2", "A2", admin);

        uint256 count = factory.getAssetCount();
        assertEq(count, 2);
    }

    function testGetAssetByIndex() public {
        factory.createAsset("Asset 1", "A1", admin);
        factory.createAsset("Asset 2", "A2", admin);

        RealWorldAsset asset = factory.getAssetByIndex(0);
        assertEq(asset.getName(), "Asset 1");

        asset = factory.getAssetByIndex(1);
        assertEq(asset.getName(), "Asset 2");
    }

    function testGetAssetByIndexOutOfBounds() public {
        factory.createAsset("Asset 1", "A1", admin);

        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetByIndex(1);
    }

    function testGetDeployedAssetsAddresses() public {
        factory.createAsset("Asset 1", "A1", admin);
        factory.createAsset("Asset 2", "A2", admin);

        address[] memory addresses = factory.getDeployedAssetsAddresses();
        assertEq(addresses.length, 2);
        assertEq(addresses[0], address(factory.getAssets()[0]));
        assertEq(addresses[1], address(factory.getAssets()[1]));
    }
}