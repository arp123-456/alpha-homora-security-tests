// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ProxyOracle.sol";

/**
 * @title HomoraBankV2
 * @notice Simplified Alpha Homora V2 bank for testing
 * @dev Tests both vulnerable and fixed versions
 */
contract HomoraBankV2 is ReentrancyGuard {
    IERC20 public immutable alphaToken;
    ProxyOracle public immutable oracle;
    
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120%
    uint256 public constant PRECISION = 1e18;
    
    // Vulnerability flag for testing
    bool public roundingVulnerable;
    
    struct Position {
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 debtShares;
    }
    
    mapping(address => Position) public positions;
    mapping(address => bool) public whitelistedSpells;
    
    uint256 public totalDebt;
    uint256 public totalDebtShares;
    
    address public governor;
    
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 shares);
    event Repaid(address indexed user, uint256 amount);
    event SpellExecuted(address indexed user, address indexed spell);
    
    modifier onlyGovernor() {
        require(msg.sender == governor, "Not governor");
        _;
    }
    
    constructor(address _alphaToken, address _oracle, bool _roundingVulnerable) {
        alphaToken = IERC20(_alphaToken);
        oracle = ProxyOracle(_oracle);
        roundingVulnerable = _roundingVulnerable;
        governor = msg.sender;
    }
    
    /**
     * @notice Deposit ALPHA as collateral
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(alphaToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        positions[msg.sender].collateralAmount += amount;
        emit Deposited(msg.sender, amount);
    }
    
    /**
     * @notice Borrow ETH against ALPHA collateral
     * @dev VULNERABLE if roundingVulnerable == true (2021 attack)
     */
    function borrow(uint256 ethAmount) external nonReentrant {
        require(ethAmount > 0, "Invalid amount");
        require(address(this).balance >= ethAmount, "Insufficient liquidity");
        
        Position storage pos = positions[msg.sender];
        require(pos.collateralAmount > 0, "No collateral");
        
        // Get collateral value from oracle
        uint256 alphaPrice = oracle.getPrice(address(alphaToken));
        uint256 collateralValueInETH = (pos.collateralAmount * PRECISION) / alphaPrice;
        
        // Calculate debt shares
        uint256 shares;
        if (roundingVulnerable) {
            // VULNERABLE: 2021 rounding error
            if (totalDebtShares == 0) {
                shares = ethAmount;
            } else {
                shares = (ethAmount * totalDebtShares) / totalDebt;
                // BUG: Can round to zero if ethAmount is small relative to totalDebt
            }
        } else {
            // FIXED: Prevent zero-share minting
            if (totalDebtShares == 0) {
                shares = ethAmount;
            } else {
                shares = (ethAmount * totalDebtShares) / totalDebt;
                require(shares > 0, "Cannot mint zero shares");
            }
        }
        
        // Check collateralization
        uint256 newTotalDebt = pos.debtAmount + ethAmount;
        uint256 maxBorrow = (collateralValueInETH * 100) / COLLATERAL_RATIO;
        require(newTotalDebt <= maxBorrow, "Insufficient collateral");
        
        // Update state
        pos.debtAmount += ethAmount;
        pos.debtShares += shares;
        totalDebt += ethAmount;
        totalDebtShares += shares;
        
        // Transfer ETH
        (bool success,) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
        
        emit Borrowed(msg.sender, ethAmount, shares);
    }
    
    /**
     * @notice Repay borrowed ETH
     */
    function repay() external payable nonReentrant {
        Position storage pos = positions[msg.sender];
        require(pos.debtAmount > 0, "No debt");
        require(msg.value <= pos.debtAmount, "Overpayment");
        
        uint256 sharesToBurn = (msg.value * pos.debtShares) / pos.debtAmount;
        
        pos.debtAmount -= msg.value;
        pos.debtShares -= sharesToBurn;
        totalDebt -= msg.value;
        totalDebtShares -= sharesToBurn;
        
        emit Repaid(msg.sender, msg.value);
    }
    
    /**
     * @notice Withdraw collateral
     */
    function withdraw(uint256 amount) external nonReentrant {
        Position storage pos = positions[msg.sender];
        require(amount <= pos.collateralAmount, "Insufficient collateral");
        
        if (pos.debtAmount > 0) {
            uint256 alphaPrice = oracle.getPrice(address(alphaToken));
            uint256 remainingCollateralValue = ((pos.collateralAmount - amount) * PRECISION) / alphaPrice;
            uint256 requiredCollateral = (pos.debtAmount * COLLATERAL_RATIO) / 100;
            require(remainingCollateralValue >= requiredCollateral, "Undercollateralized");
        }
        
        pos.collateralAmount -= amount;
        require(alphaToken.transfer(msg.sender, amount), "Transfer failed");
    }
    
    /**
     * @notice Execute custom spell
     * @dev VULNERABLE if spell not whitelisted
     */
    function execute(address spell, bytes calldata data) external nonReentrant {
        require(whitelistedSpells[spell], "Spell not whitelisted");
        
        (bool success,) = spell.call(data);
        require(success, "Spell execution failed");
        
        emit SpellExecuted(msg.sender, spell);
    }
    
    /**
     * @notice Resolve reserve (2021 vulnerability if not protected)
     * @dev VULNERABLE if not restricted to governor
     */
    function resolveReserve(uint256 amount) external onlyGovernor {
        // Reserve resolution logic
        // In 2021 attack, this was public and exploitable
    }
    
    /**
     * @notice Whitelist spell contract
     */
    function whitelistSpell(address spell, bool status) external onlyGovernor {
        whitelistedSpells[spell] = status;
    }
    
    /**
     * @notice Get position health
     */
    function getPositionHealth(address user) external view returns (uint256) {
        Position memory pos = positions[user];
        if (pos.debtAmount == 0) return type(uint256).max;
        
        uint256 alphaPrice = oracle.getPriceUnsafe(address(alphaToken));
        uint256 collateralValueInETH = (pos.collateralAmount * PRECISION) / alphaPrice;
        return (collateralValueInETH * 100) / pos.debtAmount;
    }
    
    receive() external payable {}
}