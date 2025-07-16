// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { FactoryRealWorldAssets } from "../src/FactoryRealWorldAssets.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "../src/RealWorldAssetManager.sol";

contract FactoryRealWorldAssetsGeneratedTest is Test {
    address private admin;
    FactoryRealWorldAssets private factory;

    function setUp() public {
        admin = address(0xBEEF);
        vm.startPrank(admin);
        factory = new FactoryRealWorldAssets();
        vm.stopPrank();
    }

    function testCreateAssetWorks() public {
        vm.prank(admin);
        factory.createAsset("AssetX", "AX", admin);
        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        assertEq(asset.getName(), "AssetX");
        assertEq(asset.symbol(), "AX");
    }

    function testCreateAssetEmptyNameReverts() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptyName.selector));
        vm.prank(admin);
        factory.createAsset("", "AX", admin);
    }

    function testCreateAssetEmptySymbolReverts() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptySymbol.selector));
        vm.prank(admin);
        factory.createAsset("AssetX", "", admin);
    }

    function testCreateDuplicateAssetReverts() public {
        vm.prank(admin);
        factory.createAsset("AssetX", "AX", admin);
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetAlreadyExists.selector));
        vm.prank(admin);
        factory.createAsset("AssetX", "AX", admin);
    }

    function testGetAssetsReturnsAll() public {
        vm.prank(admin);
        factory.createAsset("Asset1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset2", "A2", admin);
        RealWorldAsset[] memory assets = factory.getAssets();
        assertEq(assets.length, 2);
        assertEq(RealWorldAsset(address(assets[0])).getName(), "Asset1");
        assertEq(RealWorldAsset(address(assets[1])).getName(), "Asset2");
    }

    function testGetAssetCountReturnsCorrect() public {
        vm.prank(admin);
        factory.createAsset("Asset1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset2", "A2", admin);
        assertEq(factory.getAssetCount(), 2);
    }

    function testGetAssetByIndexWorks() public {
        vm.prank(admin);
        factory.createAsset("Asset1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset2", "A2", admin);
        RealWorldAsset asset0 = RealWorldAsset(address(factory.getAssetByIndex(0)));
        RealWorldAsset asset1 = RealWorldAsset(address(factory.getAssetByIndex(1)));
        assertEq(asset0.getName(), "Asset1");
        assertEq(asset1.getName(), "Asset2");
    }

    function testGetAssetByIndexOutOfBoundsReverts() public {
        vm.prank(admin);
        factory.createAsset("Asset1", "A1", admin);
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetByIndex(1);
    }

    function testGetDeployedAssetsAddressesWorks() public {
        vm.prank(admin);
        factory.createAsset("Asset1", "A1", admin);
        vm.prank(admin);
        factory.createAsset("Asset2", "A2", admin);
        address[] memory addresses = factory.getDeployedAssetsAddresses();
        assertEq(addresses.length, 2);
        assertEq(addresses[0], address(factory.getAssets()[0]));
        assertEq(addresses[1], address(factory.getAssets()[1]));
    }

    function testGetAssetTokenWorks() public {
        vm.prank(admin);
        factory.createAsset("AssetX", "AX", admin);
        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        RealWorldAssetToken token = factory.getAssetToken(address(asset));
        assertEq(token.name(), "AssetX");
        assertEq(token.symbol(), "AX");
    }

    function testGetAssetManagerWorks() public {
        vm.prank(admin);
        factory.createAsset("AssetX", "AX", admin);
        RealWorldAsset asset = RealWorldAsset(factory.getAssets()[0]);
        RealWorldAssetManager manager = factory.getAssetManager(address(asset));
        assertEq(address(manager.getAsset()), address(asset));
        assertEq(address(manager.getAssetToken()), address(factory.getAssetToken(address(asset))));
    }

    function testGetAssetTokenForNonExistentAssetReverts() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetToken(address(0));
    }

    function testGetAssetManagerForNonExistentAssetReverts() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetNotFound.selector));
        factory.getAssetManager(address(0));
    }
}