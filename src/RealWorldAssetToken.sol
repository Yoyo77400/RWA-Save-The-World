// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RealWorldAssetToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    uint256 public limitSupply;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address owner_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init(owner_);
        _mint(owner_, initialSupply);
        limitSupply = initialSupply * 10;
        _transferOwnership(owner_);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
