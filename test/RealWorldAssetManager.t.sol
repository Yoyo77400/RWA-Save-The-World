// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";
import { RealWorldAssetManager } from "../src/RealWorldAssetManager.sol";

contract RealWorldAssetManagerTest is Test {
    RealWorldAssetManager private assetManager;
    RealWorldAsset private asset;
    RealWorldAssetToken private assetToken;
    address private owner_;
    address private user;

    function setUp() public {
        owner_ = address(0x123);
        user = address(0x456);

        vm.startPrank(owner_);

        asset = new RealWorldAsset();
        asset.initialize("Test Asset", "TAST", owner_);

        assetToken = new RealWorldAssetToken();
        assetToken.initialize("Test Asset Token", "TAST", 1_000_000 ether, owner_);

        assetManager = new RealWorldAssetManager();
        assetManager.initialize(address(asset), address(assetToken), 1 ether, owner_);

        assetToken.approve(address(assetManager), 1_000_000 ether);
        assetToken.transfer(address(assetManager), 1_000 ether);

        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(address(assetManager.getAsset()), address(asset));
        assertEq(address(assetManager.getAssetToken()), address(assetToken));
    }

    function testBuyAssetToken() public {
        uint256 amount = 100;
        uint256 price = amount * assetManager.getPricePerToken();

        vm.deal(user, 10000 ether);

        vm.startPrank(user);

        console.log("Manager token balance:", assetToken.balanceOf(address(assetManager)));
        console.log("User ETH balance:", user.balance);
        console.log("Price per token:", assetManager.getPricePerToken());
        console.log("Calculated price:", price);

        assetManager.buyAssetToken{value: price}(amount);

        assertEq(assetToken.balanceOf(user), amount);
    }
}
