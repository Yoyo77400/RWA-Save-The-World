// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import { Test, console } from "forge-std/Test.sol";
import { FactoryRealWorldAssets } from "../src/FactoryRealWorldAssets.sol";
import { RealWorldAsset } from "../src/RealWorldAsset.sol";
import { MarketPlace } from "../src/MarketPlace.sol";

contract MarketPlaceTest is Test {
    address private admin;
    FactoryRealWorldAssets private factory;
    MarketPlace private marketPlace;
    RealWorldAsset private asset1;
    RealWorldAsset private asset2;
    address private user1;
    address private user2;
    address private user3;
    address private user4;
    address private user5;
    address private user6;
    address feeRecipient;
    uint16 feePercentage;
    MarketPlace.Sale saleTest;
    MarketPlace.Sale saleTest2;

    function setUp() public {
        admin = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);
        user3 = address(0x4);
        user4 = address(0x5);
        user5 = address(0x6);
        user6 = address(0x7);
        feeRecipient = address(0x8);
        feePercentage = 5;
    

        vm.startPrank(admin);
            factory = new FactoryRealWorldAssets();
            asset1 = factory.createAsset("Asset 1", "A1", admin);
            asset2 = factory.createAsset("Asset 2", "A2", admin);
            marketPlace = new MarketPlace();
            marketPlace.initialize(address(factory), feeRecipient, feePercentage);
            asset1.mint(user1, "https://example.com/asset1");
            asset2.mint(user2, "https://example.com/asset2");
            
            saleTest = MarketPlace.Sale({
                assetAddress: address(asset1),
                seller: user1,
                saleType: MarketPlace.SaleType.FixedPrice,
                price: 100,
                auctionEndTime: 0,
                assetId: 0,
                highestBid: 0,
                highestBidder: address(0),
                active: true
            });

            saleTest2 = MarketPlace.Sale({
                assetAddress: address(asset2),
                seller: user2,
                saleType: MarketPlace.SaleType.Auction,
                price: 0,
                auctionEndTime: block.timestamp + 10 minutes,
                assetId: 1,
                highestBid: 0,
                highestBidder: address(0),
                active: true
            });
        vm.stopPrank();
    }

    function testGetFactory() public {
        vm.startPrank(admin);
            marketPlace = new MarketPlace();
            marketPlace.initialize(address(factory), feeRecipient, feePercentage);
        vm.stopPrank();
    }

    function testGetListings() public {
        vm.startPrank(admin);
            marketPlace.listAssetFixedPrice(address(asset1), 0, MarketPlace.SaleType.FixedPrice, 100);
            marketPlace.listAssetAuction(address(asset2), 1, MarketPlace.SaleType.Auction, 50, 1);
        vm.stopPrank();

        MarketPlace.Sale[] memory listings = marketPlace.getSales();
        assertEq(listings.length, 2);
        assertEq(listings[0].assetAddress, address(asset1));
        assertEq(listings[1].assetAddress, address(asset2));
    }

    function testListAssetFixedPrice() public {
        vm.startPrank(user1);
            uint256 saleId = marketPlace.listAssetFixedPrice(address(asset1), 1, MarketPlace.SaleType.FixedPrice, 100);
        vm.stopPrank();

        MarketPlace.Sale memory sale = marketPlace.getSale(saleId);
        assertEq(sale.assetAddress, address(asset1));
        assertEq(sale.seller, user1);
        assertEq(uint8(sale.saleType), uint8(MarketPlace.SaleType.FixedPrice));
        assertEq(sale.price, 100);
        assertTrue(sale.active);
    }

    function testListAssetAuction() public {
        vm.startPrank(user2);
            uint256 saleId = marketPlace.listAssetAuction(address(asset2), 1, MarketPlace.SaleType.Auction, 50, 1);
        vm.stopPrank();

        MarketPlace.Sale memory sale = marketPlace.getSale(saleId);
        assertEq(sale.assetAddress, address(asset2));
        assertEq(sale.seller, user2);
        assertEq(uint8(sale.saleType), uint8(MarketPlace.SaleType.Auction));
        assertEq(sale.price, 50);
        assertTrue(sale.active);
    }

    function testListAssetAuctionWithInvalidParameters() public {
        vm.startPrank(user2);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.InvalidPrice.selector));
            marketPlace.listAssetAuction(address(asset2), 1, MarketPlace.SaleType.Auction, 0, 1);
        vm.stopPrank();

        vm.startPrank(user3);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.InvalidSaleType.selector));
            marketPlace.listAssetAuction(address(0), 1, MarketPlace.SaleType.Auction, 50, 1);
        vm.stopPrank();
    }

    function testListAssetFixedPriceWithInvalidParameters() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.InvalidPrice.selector));
            marketPlace.listAssetFixedPrice(address(asset1), 1, MarketPlace.SaleType.FixedPrice, 0);
        vm.stopPrank();

        vm.startPrank(user2);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.InvalidSaleType.selector));
            marketPlace.listAssetFixedPrice(address(0), 1, MarketPlace.SaleType.FixedPrice, 100);
        vm.stopPrank();
    }

    function testListAssetAlreadyListed() public {
        vm.startPrank(user1);
            marketPlace.listAssetFixedPrice(address(asset1), 0, MarketPlace.SaleType.FixedPrice, 100);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.SaleAlreadyActive.selector));
            marketPlace.listAssetFixedPrice(address(asset1), 0, MarketPlace.SaleType.FixedPrice, 100);
        vm.stopPrank();
    }

    function testPurchaseAssetNotListed() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.SaleNotFound.selector));
            marketPlace.purchaseAsset(999); // Non-existent sale ID
        vm.stopPrank();
    }

    function testPurchaseAssetWithInvalidParameters() public {
        vm.startPrank(user1);
            marketPlace.listAssetFixedPrice(address(asset1), 0, MarketPlace.SaleType.FixedPrice, 100);
        vm.stopPrank();

        vm.startPrank(user2);
            vm.expectRevert(abi.encodeWithSelector(MarketPlace.SaleNotFound.selector));
            marketPlace.purchaseAsset(0);
        vm.stopPrank();
    }


}