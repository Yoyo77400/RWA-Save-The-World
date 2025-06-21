// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "../src/RealWorldAssetManager.sol";
import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract RealWorldAssetManagerTest is Test {
    RealWorldAssetManager private assetManager;
    RealWorldAsset private asset;
    RealWorldAssetToken private assetToken;
    address private owner_;
    address private user;

    function setUp() public {
        owner_ = address(0x123);
        user = address(0x456);
        asset = new RealWorldAsset("Test Asset", "TAST", owner_);
        assetToken = new RealWorldAssetToken("Test Asset Token", "TAST", 1000000 * 10 ** 18, owner_);
        assetManager = new RealWorldAssetManager(address(asset), address(assetToken), 1, owner_);

    }

    function testInitialSetup() public {
        assertEq(address(assetManager.getAsset()), address(asset));
        assertEq(address(assetManager.getAssetToken()), address(assetToken));
    }

    function testBuyAssetToken() public {
        uint256 amount = 100 * 10 ** 18; // 100 tokens
        uint256 price = amount * assetManager.getPricePerToken();
        vm.deal(user, 10000 ether);
        vm.prank(owner_);
            assetToken.approve(address(assetManager), amount);

        vm.startPrank(user);
            assetManager.buyAssetToken{value : price}(amount);
        vm.stopPrank();

        assertEq(assetToken.balanceOf(user), amount);
    }
}