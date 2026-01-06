// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
 * @title ProxyOracle
 * @notice Price oracle with deviation limits (mimics Alpha Homora V2 oracle)
 * @dev VULNERABLE: 50% deviation may not be sufficient protection
 */
contract ProxyOracle {
    IUniswapV2Pair public immutable pair;
    
    uint256 public constant MAX_DEVIATION = 1.5e18; // 50% maximum deviation
    uint256 public constant PRECISION = 1e18;
    
    mapping(address => uint256) public lastPrice;
    mapping(address => uint256) public lastUpdateTime;
    
    event PriceUpdated(address indexed token, uint256 oldPrice, uint256 newPrice, uint256 deviation);
    event DeviationExceeded(address indexed token, uint256 deviation, uint256 maxDeviation);
    
    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
    }
    
    /**
     * @notice Get current price with deviation check
     * @dev VULNERABLE: Can be bypassed with gradual manipulation
     */
    function getPrice(address token) external returns (uint256) {
        uint256 newPrice = _fetchPrice(token);
        uint256 oldPrice = lastPrice[token];
        
        if (oldPrice > 0) {
            uint256 deviation = _calculateDeviation(oldPrice, newPrice);
            
            if (deviation > MAX_DEVIATION) {
                emit DeviationExceeded(token, deviation, MAX_DEVIATION);
                revert("Price deviation too high");
            }
            
            emit PriceUpdated(token, oldPrice, newPrice, deviation);
        }
        
        lastPrice[token] = newPrice;
        lastUpdateTime[token] = block.timestamp;
        
        return newPrice;
    }
    
    /**
     * @notice Get price without deviation check (view function)
     * @dev VULNERABLE: Can be called during manipulation
     */
    function getPriceUnsafe(address token) external view returns (uint256) {
        return _fetchPrice(token);
    }
    
    /**
     * @notice Fetch current price from Uniswap pair
     */
    function _fetchPrice(address token) internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        
        if (token == token0) {
            // Price of token0 in terms of token1
            return (uint256(reserve1) * PRECISION) / uint256(reserve0);
        } else {
            // Price of token1 in terms of token0
            return (uint256(reserve0) * PRECISION) / uint256(reserve1);
        }
    }
    
    /**
     * @notice Calculate price deviation percentage
     */
    function _calculateDeviation(uint256 oldPrice, uint256 newPrice) internal pure returns (uint256) {
        if (oldPrice == 0) return 0;
        
        uint256 diff = oldPrice > newPrice ? oldPrice - newPrice : newPrice - oldPrice;
        return (diff * PRECISION) / oldPrice;
    }
    
    /**
     * @notice Get last stored price
     */
    function getLastPrice(address token) external view returns (uint256) {
        return lastPrice[token];
    }
    
    /**
     * @notice Check if price is fresh
     */
    function isPriceFresh(address token, uint256 maxAge) external view returns (bool) {
        return block.timestamp - lastUpdateTime[token] <= maxAge;
    }
}