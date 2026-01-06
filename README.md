# Alpha Homora Security Testing Suite

## Overview
Comprehensive live security testing for Alpha Homora protocol to identify flash loan and oracle manipulation vulnerabilities using Tenderly simulation and Remix IDE.

## 🎯 Testing Objectives

This suite tests Alpha Homora V2 for:

1. **Flash Loan Oracle Manipulation** - Price feed manipulation via flash loans
2. **Rounding Error Exploits** - 2021-style debt manipulation attacks
3. **Custom Spell Vulnerabilities** - Malicious contract injection
4. **ProxyOracle Manipulation** - Deviation limit bypass attempts
5. **Low Liquidity Pool Exploits** - Single borrower attacks
6. **Reentrancy Attacks** - Callback exploitation
7. **Access Control Issues** - Unauthorized function calls

## 🏗️ Architecture

```
Alpha Homora V2 Protocol
├── AlphaToken.sol (ALPHA ERC20)
├── HomoraBankV2.sol (Core lending logic)
├── ProxyOracle.sol (Price oracle with deviation limits)
├── SpellBase.sol (Strategy execution base)
├── UniswapV2Spell.sol (Uniswap integration)
├── IronBankAdapter.sol (Cream Finance integration)
└── Test Contracts
    ├── FlashLoanAttacker.sol (Attack simulation)
    ├── MaliciousSpell.sol (Evil spell replication)
    └── SecureHomoraBank.sol (Hardened version)
```

## 🚨 Vulnerabilities Being Tested

### 1. Flash Loan Oracle Manipulation
**Attack Vector:**
- Flash loan large amount of tokens
- Swap on DEX to manipulate spot price
- Oracle reads manipulated price
- Exploit lending with inflated collateral
- Reverse swap and repay

**Expected Result:** Should be prevented by ProxyOracle deviation limits

### 2. Rounding Error Exploit (2021 Attack Replication)
**Attack Vector:**
- Deploy custom "evil spell"
- Become sole borrower in low-liquidity pool
- Borrow amounts that round to zero debt shares
- Double debt recursively (16+ iterations)
- Extract funds via debt manipulation

**Expected Result:** Should be fixed post-2021 patches

### 3. ProxyOracle Deviation Bypass
**Attack Vector:**
- Manipulate price within deviation limits (50%)
- Use multiple transactions to stay under threshold
- Gradually inflate collateral value
- Borrow maximum at manipulated price

**Expected Result:** Test if 50% deviation is sufficient protection

### 4. Custom Spell Injection
**Attack Vector:**
- Deploy malicious spell contract
- Bypass collateral checks
- Create fake positions
- Extract funds

**Expected Result:** Should be prevented by whitelist controls

## 📦 Installation

```bash
# Clone repository
git clone https://github.com/arp123-456/alpha-homora-security-tests.git
cd alpha-homora-security-tests

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Configure Tenderly and RPC URLs in .env
```

## 🔧 Configuration

Edit `.env` file:
```bash
# Tenderly Configuration
TENDERLY_API_KEY=your_tenderly_api_key
TENDERLY_USER=your_tenderly_username
TENDERLY_PROJECT=your_project_name

# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
MAINNET_FORK_BLOCK=18500000

# Alpha Homora V2 Addresses (Mainnet)
HOMORA_BANK_V2=0xba5eBAf3fc1Fcca67147050Bf80462393814E54B
ALPHA_TOKEN=0xa1faa113cbE53436Df28FF0aEe54275c13B40975
PROXY_ORACLE=0x1E5BDdd0cDF8839d6b27b34927869eF0AD7bf692

# Test Configuration
FLASH_LOAN_AMOUNT=10000000000000000000000000
ATTACK_POOL=sUSD
```

## 🧪 Running Tests

### All Tests
```bash
npm test
```

### Specific Test Suites
```bash
# Flash loan oracle manipulation
npm run test:oracle

# Rounding error exploit (2021 replication)
npm run test:rounding

# Custom spell attacks
npm run test:spell

# ProxyOracle deviation tests
npm run test:deviation

# Comprehensive security audit
npm run test:audit
```

### Tenderly Simulation
```bash
# Create Tenderly fork
npm run tenderly:fork

# Deploy contracts to fork
npm run tenderly:deploy

# Run attack simulation
npm run tenderly:simulate

# Analyze results
npm run tenderly:analyze
```

## 🎨 Remix IDE Testing

### Step 1: Setup Contracts
1. Open [Remix IDE](https://remix.ethereum.org)
2. Copy contracts from `contracts/` folder
3. Compile with Solidity 0.8.20
4. Connect to Mainnet fork or testnet

### Step 2: Deploy Test Environment
```javascript
// Deploy in order:
1. AlphaToken
2. MockUniswapV2Pair (for price manipulation)
3. ProxyOracle(uniswapPair)
4. HomoraBankV2(alphaToken, oracle)
5. FlashLoanAttacker(bank, oracle)
```

### Step 3: Setup Initial State
```javascript
// Add liquidity to Uniswap pair
alphaToken.approve(uniswapPair, 10000000e18);
uniswapPair.addLiquidity(10000000e18, {value: 1000e18});

// Fund bank with lending capital
owner.sendTransaction({to: bank, value: 500e18});

// Fund attacker
alphaToken.transfer(attacker, 50000000e18);
```

### Step 4: Execute Attack Scenarios

#### **Scenario A: Oracle Manipulation**
```javascript
// Attempt to manipulate oracle price
attacker.executeOracleManipulation(5000000e18);

// Check if oracle deviation limits prevent exploit
uint256 price = oracle.getPrice(alphaToken);
// Should revert if manipulation exceeds 50% deviation
```

#### **Scenario B: Rounding Error Exploit**
```javascript
// Deploy malicious spell
MaliciousSpell spell = new MaliciousSpell(bank);

// Attempt 2021-style attack
attacker.executeRoundingAttack(spell, 1000e18);

// Check if debt shares calculated correctly
// Should fail if 2021 patches are in place
```

#### **Scenario C: Flash Loan Attack**
```javascript
// Execute flash loan attack
attacker.executeFlashLoanAttack{value: 1e18}(
    10000000e18,  // Flash loan amount
    alphaToken,   // Token to borrow
    1000e18       // Collateral amount
);

// Verify profit/loss
uint256 profit = attacker.calculateProfit();
```

### Step 5: Verify Results
```javascript
// Check attack success
bool attackSuccessful = attacker.wasAttackSuccessful();

// Check protocol state
uint256 bankBalance = address(bank).balance;
uint256 attackerProfit = attacker.getProfit();

// Verify security measures
bool oracleProtected = oracle.isProtected();
bool roundingFixed = bank.isRoundingFixed();
```

## 📊 Test Scenarios

### Scenario 1: Basic Oracle Manipulation
```
Initial State:
- Pool: 10M ALPHA / 1000 ETH
- Price: 10,000 ALPHA per ETH
- Oracle Deviation Limit: 50%

Attack:
1. Flash loan 50M ALPHA
2. Swap 50M ALPHA → ETH
3. Price drops to 60,000 ALPHA per ETH (83% drop)
4. Oracle should REJECT (exceeds 50% limit)

Expected Result: ❌ Attack PREVENTED by deviation limit
```

### Scenario 2: Gradual Price Manipulation
```
Initial State:
- Pool: 10M ALPHA / 1000 ETH
- Price: 10,000 ALPHA per ETH
- Oracle Deviation Limit: 50%

Attack:
1. Swap 5M ALPHA → ETH (40% price change)
2. Wait for oracle update
3. Swap another 5M ALPHA → ETH (40% more)
4. Borrow at manipulated price

Expected Result: ⚠️ Test if multi-step manipulation works
```

### Scenario 3: 2021 Rounding Error Replication
```
Initial State:
- sUSD Pool: 100,000 sUSD available
- No other borrowers (sole borrower scenario)
- Attacker has custom spell contract

Attack:
1. Deploy malicious spell
2. Borrow 1000 sUSD (becomes sole borrower)
3. Borrow 999 sUSD (just under total debt)
4. Repeat 16 times, doubling each time
5. Debt inflates without share increase

Expected Result: ✅ Attack PREVENTED (should be fixed)
```

### Scenario 4: Low Liquidity Pool Exploit
```
Initial State:
- Create new pool with minimal liquidity
- Pool: 10,000 ALPHA / 1 ETH
- High price impact potential

Attack:
1. Flash loan 1M ALPHA
2. Swap in low-liquidity pool
3. Massive price manipulation (99%+)
4. Exploit lending protocol

Expected Result: ⚠️ Test if low-liquidity pools are protected
```

### Scenario 5: Custom Spell Injection
```
Initial State:
- Attacker deploys malicious spell
- Spell bypasses collateral checks
- Attempts to create fake position

Attack:
1. Deploy MaliciousSpell contract
2. Call bank.execute(maliciousSpell, data)
3. Attempt to borrow without collateral

Expected Result: ✅ Attack PREVENTED by whitelist
```

## 🛡️ Security Measures Being Tested

### 1. ProxyOracle Deviation Limits
```solidity
// Should prevent extreme price manipulation
uint256 constant MAX_DEVIATION = 1.5e18; // 50%

function getPrice(address token) external view returns (uint256) {
    uint256 newPrice = fetchPrice(token);
    uint256 oldPrice = lastPrice[token];
    
    uint256 deviation = abs(newPrice - oldPrice) * 1e18 / oldPrice;
    require(deviation <= MAX_DEVIATION, "Price deviation too high");
    
    return newPrice;
}
```

**Test:** Can attacker bypass with gradual manipulation?

### 2. Rounding Error Fixes
```solidity
// Should prevent zero-debt share calculation
function borrow(uint256 amount) external {
    uint256 shares = (amount * totalShares) / totalDebt;
    require(shares > 0, "Cannot mint zero shares"); // Fix
    
    totalShares += shares;
    totalDebt += amount;
    userShares[msg.sender] += shares;
}
```

**Test:** Can attacker still exploit rounding?

### 3. Spell Whitelist
```solidity
// Should prevent malicious spell execution
mapping(address => bool) public whitelistedSpells;

function execute(address spell, bytes calldata data) external {
    require(whitelistedSpells[spell], "Spell not whitelisted");
    ISpell(spell).execute(data);
}
```

**Test:** Can attacker bypass whitelist?

### 4. Access Controls
```solidity
// Should prevent unauthorized calls
function resolveReserve(uint256 amount) external {
    require(msg.sender == governor, "Not authorized"); // Fix
    // Reserve resolution logic
}
```

**Test:** Are all critical functions protected?

## 📈 Expected Test Results

### Vulnerable Oracle (No Protection)
```
✓ Flash loan attack successful
  - Price manipulated: 83% drop
  - Attacker profit: 450 ETH
  - Protocol loss: 450 ETH
  - Attack duration: 1 block

✓ Gradual manipulation successful
  - Multi-step price change: 60% total
  - Attacker profit: 200 ETH
```

### Protected Oracle (With Deviation Limits)
```
✗ Flash loan attack prevented
  - Price manipulation detected
  - Deviation: 83% > 50% limit
  - Transaction reverted
  
⚠ Gradual manipulation partially successful
  - Each step within 50% limit
  - Total manipulation: 60%
  - Requires multiple blocks
```

### Fixed Rounding Errors
```
✗ 2021-style attack prevented
  - Zero-share minting blocked
  - Debt shares calculated correctly
  - Recursive doubling prevented
```

### Whitelist Protection
```
✗ Custom spell injection prevented
  - Malicious spell not whitelisted
  - Execution reverted
  - Collateral checks enforced
```

## 🔍 Tenderly Analysis Features

### Transaction Simulation
- Step-by-step execution trace
- State changes visualization
- Gas usage analysis
- Event logs inspection
- Call stack analysis

### Debugger
- Line-by-line contract execution
- Variable inspection at each step
- Storage slot changes
- Memory/stack analysis
- Revert reason detection

### Fork Testing
- Test on mainnet fork with real contracts
- Simulate large flash loans
- Test with actual Alpha Homora V2 deployment
- Analyze attack profitability
- No real funds at risk

### Security Analysis
- Vulnerability detection
- Access control verification
- Reentrancy check
- Integer overflow/underflow
- Gas optimization

## 📚 Tools & Resources

### Testing Tools
- **Hardhat** - Smart contract development
- **Tenderly** - Transaction simulation and debugging
- **Remix IDE** - Browser-based Solidity IDE
- **Foundry** - Fast Solidity testing (optional)
- **Slither** - Static analysis tool

### Alpha Homora Resources
- **Official Site:** https://homora-v2.alphaventuredao.io
- **GitHub:** https://github.com/AlphaFinanceLab/alpha-homora-v2-contract
- **Docs:** https://alphafinancelab.gitbook.io/alpha-homora-v2/
- **Audits:** OpenZeppelin, Quantstamp, Peckshield

### Security Resources
- **2021 Exploit Analysis:** Detailed attack breakdown
- **OpenZeppelin Audit:** May 2021 security review
- **Rekt News:** Alpha Homora incident report
- **Immunefi:** Bug bounty program

## ⚠️ Security Warnings

1. **Test Environment Only** - Never test on mainnet with real funds
2. **Educational Purpose** - For security research and learning
3. **Responsible Disclosure** - Report vulnerabilities to Alpha Finance
4. **No Malicious Use** - Do not use for actual attacks
5. **Legal Compliance** - Follow all applicable laws

## 🚀 Quick Start Guide

### 1. Local Testing (Hardhat)
```bash
npm install
npm test
```

### 2. Tenderly Simulation
```bash
# Setup Tenderly
npm run tenderly:setup

# Create fork
npm run tenderly:fork

# Run simulation
npm run tenderly:simulate
```

### 3. Remix Testing
1. Copy contracts to Remix
2. Deploy on Remix VM or testnet
3. Execute attack scenarios
4. Analyze results

## 📝 Test Reports

After running tests, reports are generated in:
- `reports/security-audit.json` - Comprehensive audit results
- `reports/attack-simulations.json` - Attack scenario results
- `reports/tenderly-traces/` - Transaction traces
- `reports/vulnerability-summary.md` - Executive summary

## 🎯 Success Criteria

### Security Tests Pass If:
- ✅ Oracle manipulation prevented by deviation limits
- ✅ Rounding errors fixed (zero-share minting blocked)
- ✅ Custom spell injection prevented by whitelist
- ✅ Access controls protect critical functions
- ✅ Flash loan attacks unprofitable
- ✅ Low liquidity pools protected

### Security Tests Fail If:
- ❌ Oracle can be manipulated beyond limits
- ❌ Rounding errors still exploitable
- ❌ Malicious spells can be executed
- ❌ Unauthorized access to critical functions
- ❌ Flash loan attacks profitable
- ❌ Low liquidity pools vulnerable

## 🤝 Contributing

Found a vulnerability? Want to add more test scenarios?
1. Fork the repository
2. Create feature branch
3. Add tests and documentation
4. Submit pull request
5. Responsible disclosure to Alpha Finance

## 📄 License

MIT License - Educational purposes only

## ⚠️ Disclaimer

**These tests are for security research and educational purposes only. The contracts may contain intentional vulnerabilities for testing. DO NOT use on mainnet or with real funds. Always conduct responsible security research and disclose vulnerabilities to the protocol team.**

---

**Repository:** https://github.com/arp123-456/alpha-homora-security-tests
**Documentation:** [Full Docs](./docs/)
**Issues:** [Report Issues](https://github.com/arp123-456/alpha-homora-security-tests/issues)
**Security:** [Responsible Disclosure](./SECURITY.md)