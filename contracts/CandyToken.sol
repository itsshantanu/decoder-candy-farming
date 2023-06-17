//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CandyToken
 * @dev Token extends of Ownable Interface and ERC20 Interface
 * @dev Token that can be minted and spent by the owner.
 * https://docs.openzeppelin.com/contracts/4.x/access-control
 * https://docs.openzeppelin.com/contracts/4.x/erc20
 */
contract CandyToken is ERC20, Ownable {
    constructor() ERC20("CandyToken", "CANDY") {}

    /**
     * @dev This function mint assign a number specific of tokens to a specific user address
     * we overrided the function mint for declare who can call the function, just the owner
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// (UPDATE) `transferOwnership` is already an externally-facing method inherited from `Ownable`
    /// Thanks @brianunlam for pointing this out
    ///
    /// function _transferOwnership(address newOwner) public onlyOwner {
    ///     transferOwnership(newOwner);
    /// }
}
