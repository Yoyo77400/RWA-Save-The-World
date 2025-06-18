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

        RealWorldAsset asset = factory.createAsset(name, symbol);

        assertEq(asset.getName(), name);
        assertEq(asset.symbol(), symbol);
        assertEq(address(asset), address(factory.getAssets()[0]));
    }

    function testCreateAssetWithEmptyName() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptyName.selector));
        factory.createAsset("", "TAST");
    }

    function testCreateAssetWithEmptySymbol() public {
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.EmptySymbol.selector));
        factory.createAsset("Test Asset", "");
    }

    function testCreateDuplicateAsset() public {
        factory.createAsset("Test Asset", "TAST");
        vm.expectRevert(abi.encodeWithSelector(FactoryRealWorldAssets.AssetAlreadyExists.selector));
        factory.createAsset("Test Asset", "TAST");
    }
}