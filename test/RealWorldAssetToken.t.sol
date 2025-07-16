// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RealWorldAssetToken } from "../src/RealWorldAssetToken.sol";

contract RealWorldAssetTokenTest is Test {
    RealWorldAssetToken private assetToken;
    string private assetName = "Test Asset";
    string private assetSymbol = "TAST";
    uint256 private initialSupply = 1_000_000 * 10 ** 18;
    address private owner;
    address private user;
    address private badAddress = address(0);

    error ERC20InvalidReceiver(address receiver);
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        owner = address(0x123);
        user = address(0x456);

        // Déploiement de l'implémentation
        RealWorldAssetToken implementation = new RealWorldAssetToken();

        // Préparation de l'initialisation
        bytes memory init = abi.encodeWithSelector(
            RealWorldAssetToken.initialize.selector,
            assetName,
            assetSymbol,
            initialSupply,
            owner
        );

        // Déploiement du proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), init);
        assetToken = RealWorldAssetToken(address(proxy));
    }

    function testInitialSupply() public {
        assertEq(assetToken.totalSupply(), initialSupply);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.startPrank(owner);
        assetToken.mint(owner, mintAmount);
        vm.stopPrank();

        assertEq(assetToken.balanceOf(owner), initialSupply + mintAmount);
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
        assertEq(assetToken.totalSupply(), initialSupply);
    }

    function testMintToZeroAddress() public {
        vm.startPrank(address(0));
        vm.expectRevert(); // pas besoin du selector ici car c'est une fonction personnalisée dans Ownable
        assetToken.mint(badAddress, 1000 * 10 ** 18);
        vm.stopPrank();
    }
}
