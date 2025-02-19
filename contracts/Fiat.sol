// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Fiat is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    event CashOut(address from, uint256 amount, string remark);

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(initialOwner) ERC20Permit(name) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function cashout(uint256 amount, string calldata remark) public {
        _transfer(msg.sender, owner(), amount);
        emit CashOut(msg.sender, amount, remark);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
