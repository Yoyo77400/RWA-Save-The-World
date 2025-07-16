// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721URIStorageUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { ERC721BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RealWorldAsset is Initializable,
                           ERC721Upgradeable,
                           ERC721URIStorageUpgradeable,
                           ERC721BurnableUpgradeable,
                           OwnableUpgradeable,
                           PausableUpgradeable
{
    uint256 private _tokenIdCounter;

    error LimitExceeded();
    error BadAddress();

    function initialize(string memory name_, string memory symbol_, address _owner) public initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init(_owner);
        __Pausable_init();
        _tokenIdCounter = 0;
    }

    function mint(address to, string memory uri_) external onlyOwner whenNotPaused {
        if (to == address(0)) revert BadAddress();

        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri_);
        _tokenIdCounter++;
    }

    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function getName() external view returns (string memory) {
        return name();
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURI(tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
