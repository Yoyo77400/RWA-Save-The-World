// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import { Test, console } from "forge-std/Test.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RealWorldAssetTokenTest is Test {

    RealWorldAssetToken private assetToken;
    string private assetName = "Test Asset";
    string private assetSymbol = "TAST";
    uint256 private initialSupply;
    address private owner;
    address private user;
    address private badAddress = address(0);

    error ERC20InvalidReceiver(address receiver);
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        owner = address(0x123);
        user = address(0x456);
        vm.startPrank(owner);
            assetToken = new RealWorldAssetToken(assetName, assetSymbol, initialSupply, owner);
        vm.stopPrank();
    }

    function testInitialSupply() public {
        assertEq(assetToken.totalSupply(), initialSupply);
    }

    function testMint() public {
        vm.startPrank(owner);
            uint256 mintAmount = 1000 * 10 ** 18;
            assetToken.mint(owner, mintAmount);
        vm.stopPrank();
        assertEq(assetToken.balanceOf(owner), mintAmount);
        assertEq(assetToken.totalSupply(), initialSupply + mintAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 500 * 10 ** 18;
        vm.startPrank(owner);
            assetToken.mint(owner, burnAmount);
            uint256 userBalanceBefore = assetToken.balanceOf(owner);
            assetToken.burn(burnAmount);
        vm.stopPrank();
        assertEq(assetToken.balanceOf(owner), userBalanceBefore - burnAmount);
        assertEq(assetToken.totalSupply(), initialSupply + burnAmount - burnAmount);
    }

    function testMintToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(0)));
        vm.startPrank(address(0));
        assetToken.mint(badAddress, 1000 * 10 ** 18);
        vm.stopPrank();
    }
    
}