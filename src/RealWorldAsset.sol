// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract RealWorldAsset is ERC721URIStorage, Ownable, Pausable {
    uint256 private _tokenIdCounter;
    error LimitExceeded();
    error BadAddress();

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) Pausable() {
        _tokenIdCounter = 0;
    }

    function mint(address to, string memory tokenURI) external onlyOwner whenNotPaused {
        if (to == address(0)) revert BadAddress();
        if (_tokenIdCounter >= 1) revert LimitExceeded();

        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
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

    function pause () external onlyOwner {
        _pause();
    }
    function unpause () external onlyOwner {
        _unpause();
    }

}