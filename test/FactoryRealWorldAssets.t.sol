// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { FactoryRealWorldAssets } from "../src/FactoryRealWorldAssets.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "../src/RealWorldAssetManager.sol";

contract FactoryRealWorldAssetsTest is Test {
    address private admin;
    FactoryRealWorldAssets private factory;

    function setUp() public {
        admin = address(0x1);
        vm.startPrank(admin);
        factory = new FactoryRealWorldAssets(); // msg.sender = admin
        vm.stopPrank();
    }

    function testCreateAsset() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";
        vm.prank(admin);
        factory.createAsset(name, symbol, admin);

        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        RealWorldAssetToken assetToken = RealWorldAssetToken(factory.getAssetToken(address(asset)));
        RealWorldAssetManager assetManager = RealWorldAssetManager(factory.getAssetManager(address(asset)));

        assertEq(asset.getName(), name);
        assertEq(asset.symbol(), symbol);
        assertEq(address(asset), address(factory.getAssets()[0]));
        assertEq(address(assetToken), address(factory.getAssetToken(address(asset))));
        assertEq(address(assetManager), address(factory.getAssetManager(address(asset))));
    }

    function testCreateAssetWithEmptyName() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptyName.selector));
        vm.prank(admin);
        factory.createAsset("", "TAST", admin);
    }

    function testCreateAssetWithEmptySymbol() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptySymbol.selector));
        vm.prank(admin);
        factory.createAsset("Test Asset", "", admin);
    }

    function testCreateDuplicateAsset() public {
        vm.prank(admin);
        factory.createAsset("Test Asset", "TAST", admin);
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetAlreadyExists.selector));
        vm.prank(admin);
        factory.createAsset("Test Asset", "TAST", admin);
    }

    function testGetAssets() public {
        vm.prank(admin);
        factory.createAsset("Asset 1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset 2", "A2", admin);

        RealWorldAsset[] memory assets = factory.getAssets();
        assertEq(assets.length, 2);
        assertEq(RealWorldAsset(address(assets[0])).getName(), "Asset 1");
        assertEq(RealWorldAsset(address(assets[1])).getName(), "Asset 2");
    }

    function testGetAssetCount() public {
        vm.prank(admin);
        factory.createAsset("Asset 1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset 2", "A2", admin);

        uint256 count = factory.getAssetCount();
        assertEq(count, 2);
    }

    function testGetAssetByIndex() public {
        vm.prank(admin);
        factory.createAsset("Asset 1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset 2", "A2", admin);

        RealWorldAsset asset = RealWorldAsset(address(factory.getAssetByIndex(0)));
        assertEq(asset.getName(), "Asset 1");

        asset = RealWorldAsset(address(factory.getAssetByIndex(1)));
        assertEq(asset.getName(), "Asset 2");
    }

    function testGetAssetByIndexOutOfBounds() public {
        vm.prank(admin);
        factory.createAsset("Asset 1", "A1", admin);
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetByIndex(1);
    }

    function testGetDeployedAssetsAddresses() public {
        vm.prank(admin);
        factory.createAsset("Asset 1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset 2", "A2", admin);

        address[] memory addresses = factory.getDeployedAssetsAddresses();
        assertEq(addresses.length, 2);
        assertEq(addresses[0], address(factory.getAssets()[0]));
        assertEq(addresses[1], address(factory.getAssets()[1]));
    }

    function testGetAssetToken() public {
        vm.prank(admin);
        factory.createAsset("Test Asset", "TAST", admin);
        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        RealWorldAssetToken assetToken = factory.getAssetToken(address(asset));
        assertEq(assetToken.name(), "Test Asset");
        assertEq(assetToken.symbol(), "TAST");
    }

    function testGetAssetManager() public {
        vm.prank(admin);
        factory.createAsset("Test Asset", "TAST", admin);
        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        RealWorldAssetManager assetManager = factory.getAssetManager(address(asset));
        assertEq(address(assetManager.getAsset()), address(asset));
        assertEq(address(assetManager.getAssetToken()), address(factory.getAssetToken(address(asset))));
    }

    function testGetAssetTokenForNonExistentAsset() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetToken(address(0));
    }

    function testGetAssetManagerForNonExistentAsset() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetManager(address(0));
    }
}