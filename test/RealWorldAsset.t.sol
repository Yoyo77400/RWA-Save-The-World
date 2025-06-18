// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
// Make sure OpenZeppelin contracts are installed and the path is correct
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RealWorldAssetTest is Test {
    address private admin;
    address private user;
    RealWorldAsset private asset;

    function setUp() public {

        admin = address(0x1);
        user = address(0x2);
        vm.startPrank(admin);
            asset = new RealWorldAsset("Test Asset", "TAST");
        vm.stopPrank();
    }

    function testMintByAdmin() public {
        address to = address(0x1);
        string memory tokenURI = "https://example.com/token/1";
        uint256 counter = 0;

        vm.warp(block.timestamp);
            vm.startPrank(admin);
                asset.mint(to, tokenURI);
                counter++;
            vm.stopPrank();

        uint256 tokenId = asset.currentTokenId() - 1; // Last minted token ID
        assertEq(asset.ownerOf(tokenId), to);
        assertEq(asset.getTokenURI(tokenId), tokenURI);
        assertEq(asset.currentTokenId(), counter);
    }

    function testMintByNonAdmin() public {
        address to = address(0x2);
        string memory tokenURI = "https://example.com/token/1";
        uint256 counter = 0;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vm.warp(block.timestamp);
        vm.startPrank(user);
            asset.mint(to, tokenURI);
            counter++;
        vm.stopPrank();
    }

    function testMintToZeroAddress() public {
        string memory tokenURI = "https://example.com/token/1";

        vm.expectRevert(abi.encodeWithSelector(RealWorldAsset.BadAddress.selector));
        vm.warp(block.timestamp);
        vm.startPrank(admin);
            asset.mint(address(0), tokenURI);
        vm.stopPrank();
    }

    function testGetName() public {
        string memory expectedName = "Test Asset";
        assertEq(asset.getName(), expectedName);
    }

    function testGetTokenURI() public {
        address to = address(0x1);
        string memory tokenURI = "https://example.com/token/1";

        vm.warp(block.timestamp);
        vm.startPrank(admin);
            asset.mint(to, tokenURI);
        vm.stopPrank();

        uint256 tokenId = asset.currentTokenId() - 1;
        assertEq(asset.getTokenURI(tokenId), tokenURI);
    }

    function testPause() public {
        vm.startPrank(admin);
            asset.pause();
        vm.stopPrank();

        (bool paused, ) = address(asset).call(abi.encodeWithSignature("paused()"));
        assertTrue(paused, "Contract should be paused");
    }

    function testUnpause() public {

        vm.startPrank(admin);
            asset.pause();
        vm.stopPrank();

        vm.startPrank(admin);
            asset.unpause();
        vm.stopPrank();

        (bool paused, ) = address(asset).call(abi.encodeWithSignature("unpaused()"));
        assertFalse(paused, "Contract should be unpaused");
    }

}