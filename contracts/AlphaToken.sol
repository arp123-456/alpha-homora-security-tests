// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AlphaToken
 * @notice ALPHA token for testing (mimics real ALPHA token)
 */
contract AlphaToken is ERC20, Ownable {
    constructor() ERC20("Alpha Token", "ALPHA") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000_000 * 10**18); // 1B tokens
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}