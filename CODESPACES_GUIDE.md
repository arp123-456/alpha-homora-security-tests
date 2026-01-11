# 🚀 GitHub Codespaces Setup Guide - LP Oracle Security Scanner

## Quick Start (1-Click Setup)

### Step 1: Open in Codespaces
1. Go to: https://github.com/arp123-456/alpha-homora-security-tests
2. Click the green **"Code"** button
3. Select **"Codespaces"** tab
4. Click **"Create codespace on main"**

### Step 2: Wait for Automatic Setup (~5 minutes)
The devcontainer will automatically install:
- ✅ Foundry (forge, cast, anvil)
- ✅ Echidna (smart contract fuzzer)
- ✅ Slither (static analyzer)
- ✅ Mythril (security analyzer)
- ✅ Aderyn (Rust-based analyzer)
- ✅ Halmos (symbolic testing)
- ✅ Python, Node.js, Rust toolchains

### Step 3: Verify Installation
```bash
# Check installations
forge --version
echidna-test --version
slither --version

# Or run verification script
make help
```

---

## 🎯 Running Security Scans

### Scan All Protocols
```bash
make scan-all
```

This will scan:
- Uniswap V2 LP tokens
- Curve LP tokens
- Balancer LP tokens
- SushiSwap LP tokens

### Scan Specific Protocol
```bash
# Uniswap V2
make scan-uniswap-v2

# Curve
make scan-curve

# Balancer
make scan-balancer
```

---

## 🔍 Running Specific Tests

### 1. Spot Price Manipulation
```bash
make test-spot-price
```

**What it tests:**
- Flash loan attacks on LP pricing
- Single-block price manipulation
- Deviation limit effectiveness

**Expected Output:**
```
Running 5 tests for test/UniswapV2Oracle.t.sol:UniswapV2OracleTest
[PASS] testSpotPriceManipulation() (gas: 234567)
[FAIL] testSpotPriceWithoutProtection() (gas: 123456)
  Error: Price deviation too high
[PASS] testTWAPProtection() (gas: 345678)
```

### 2. Flash Loan Attacks
```bash
make test-flash-loan
```

**What it tests:**
- 2000 ETH flash loan scenarios
- ALPHA token flash loan scenarios
- Multi-step manipulation

### 3. Reentrancy Attacks
```bash
make test-reentrancy
```

**What it tests:**
- Read-only reentrancy
- Cross-function reentrancy
- Callback manipulation

### 4. Donation Attacks
```bash
make test-donation
```

**What it tests:**
- Direct token transfers to pools
- LP token price inflation
- Internal accounting bypass

---

## 🦔 Fuzzing with Echidna

### Basic Fuzzing
```bash
make fuzz-echidna
```

### Intense Fuzzing (100K runs)
```bash
make fuzz-echidna-intense
```

**What Echidna finds:**
- Edge cases in price calculations
- Integer overflow/underflow
- Invariant violations
- Unexpected state transitions

**Example Output:**
```
echidna-test: Analyzing contract...
echidna-test: Running 50000 tests...

echidna_test_price_manipulation: failed!
  Call sequence:
    1. swap(1000000000000000000000)
    2. getPrice() -> manipulated price
    3. borrow(500000000000000000000)
  
  Counterexample found in 12345 tests
```

---

## 🐍 Static Analysis with Slither

### Run Slither
```bash
make slither
```

**Detectors enabled:**
- `reentrancy-eth` - Reentrancy vulnerabilities
- `price-manipulation` - Price oracle issues
- `oracle-manipulation` - Oracle vulnerabilities
- `timestamp` - Timestamp dependencies
- `weak-prng` - Weak randomness

**Example Output:**
```
INFO:Slither:. analyzed (42 contracts)

UniswapV2Oracle.getPrice() (src/UniswapV2Oracle.sol#45-52) uses a dangerous spot price:
  - price = (reserve0 * 1e18) / reserve1 (line 48)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#price-manipulation

HIGH: Spot price manipulation detected
MEDIUM: Missing TWAP implementation
LOW: Centralized oracle control
```

---

## 🔮 Symbolic Execution with Mythril

### Run Mythril
```bash
make mythril
```

**What Mythril finds:**
- Integer arithmetic issues
- Reentrancy vulnerabilities
- Access control problems
- Unchecked external calls

---

## 📊 Generate Reports

### Comprehensive Report
```bash
make report
```

Generates:
- `reports/summary.md` - Executive summary
- `reports/foundry-tests.json` - Test results
- `reports/slither.json` - Slither findings
- `reports/mythril.json` - Mythril analysis

### HTML Report
```bash
make report-html
```

Opens interactive HTML dashboard with:
- Vulnerability breakdown
- Protocol comparison
- Test coverage
- Recommendations

---

## 🎨 Example: Testing Your Own LP Oracle

### Step 1: Create Your Contract
```solidity
// src/MyLPOracle.sol
pragma solidity ^0.8.20;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MyLPOracle {
    IUniswapV2Pair public pair;
    
    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
    }
    
    function getPrice() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return (reserve0 * 1e18) / reserve1;
    }
}
```

### Step 2: Create Test
```solidity
// test/MyLPOracle.t.sol
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyLPOracle.sol";

contract MyLPOracleTest is Test {
    MyLPOracle oracle;
    
    function setUp() public {
        // Setup test environment
    }
    
    function testSpotPriceManipulation() public {
        // Test manipulation
    }
}
```

### Step 3: Run Tests
```bash
forge test --match-contract MyLPOracle -vvv
```

### Step 4: Run All Analyzers
```bash
# Slither
slither src/MyLPOracle.sol

# Echidna
echidna-test src/MyLPOracle.sol --contract MyLPOracle

# Mythril
myth analyze src/MyLPOracle.sol
```

---

## 🔧 Advanced Usage

### Custom Fuzz Runs
```bash
# 100K fuzz runs
forge test --fuzz-runs 100000

# Specific seed
forge test --fuzz-seed 12345
```

### Fork Testing
```bash
# Start Anvil with mainnet fork
make anvil

# In another terminal, run tests
forge test --fork-url http://localhost:8545
```

### Gas Profiling
```bash
make test-gas
```

### Coverage Report
```bash
make test-coverage
```

Opens `coverage/index.html` with line-by-line coverage.

---

## 📈 Understanding Results

### Vulnerability Severity

#### 🔴 CRITICAL
- Spot price manipulation without TWAP
- Reentrancy allowing fund drainage
- Missing access controls on critical functions

**Action:** Fix immediately before deployment

#### 🟠 HIGH
- Read-only reentrancy
- Insufficient deviation limits
- Donation attack vectors

**Action:** Fix before mainnet deployment

#### 🟡 MEDIUM
- Missing freshness checks
- Centralized oracle control
- Weak randomness

**Action:** Fix in next update

#### 🟢 LOW
- Gas optimization issues
- Code quality improvements
- Documentation gaps

**Action:** Address when convenient

---

## 🎯 Common Vulnerabilities Found

### 1. Spot Price Oracle (CRITICAL)
```solidity
// VULNERABLE
function getPrice() external view returns (uint256) {
    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    return (reserve0 * 1e18) / reserve1; // ❌ Spot price
}

// SECURE
function getPrice() external view returns (uint256) {
    return getTWAP(30 minutes); // ✅ TWAP
}
```

### 2. Read-Only Reentrancy (HIGH)
```solidity
// VULNERABLE
function swap() external {
    callback(msg.sender); // ❌ Callback before update
    updateReserves();
}

// SECURE
function swap() external nonReentrant {
    updateReserves(); // ✅ Update first
    callback(msg.sender);
}
```

### 3. Donation Attack (HIGH)
```solidity
// VULNERABLE
function getLPValue() external view returns (uint256) {
    return token.balanceOf(address(this)); // ❌ Uses balance
}

// SECURE
function getLPValue() external view returns (uint256) {
    return _internalBalance; // ✅ Internal accounting
}
```

---

## 🐛 Troubleshooting

### Issue: Foundry not found
```bash
# Reinstall Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Issue: Echidna not found
```bash
# Reinstall Echidna
wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz
tar -xzf echidna-2.2.1-Linux.tar.gz
sudo mv echidna /usr/local/bin/
```

### Issue: Slither errors
```bash
# Reinstall Slither
pip3 install --upgrade slither-analyzer
```

### Issue: Out of memory
```bash
# Reduce fuzz runs
forge test --fuzz-runs 1000
```

---

## 📚 Additional Resources

### Documentation
- [Foundry Book](https://book.getfoundry.sh/)
- [Echidna Tutorial](https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna)
- [Slither Documentation](https://github.com/crytic/slither)

### Example Reports
- `reports/uniswap-v2-analysis.md`
- `reports/curve-analysis.md`
- `reports/balancer-analysis.md`

### Video Tutorials
- Setting up Codespaces
- Running security scans
- Interpreting results
- Fixing vulnerabilities

---

## ✅ Checklist for Production

Before deploying your LP oracle:

- [ ] Run `make test` - All tests pass
- [ ] Run `make fuzz-echidna` - No vulnerabilities found
- [ ] Run `make analyze` - Clean Slither/Mythril reports
- [ ] Implement TWAP (30+ minute window)
- [ ] Add deviation limits (5% maximum)
- [ ] Add reentrancy guards
- [ ] Use internal accounting (not balanceOf)
- [ ] Add freshness checks
- [ ] Multi-oracle validation
- [ ] Professional audit completed
- [ ] Bug bounty program launched

---

## 🎓 Learning Path

### Beginner
1. Run `make scan-uniswap-v2`
2. Read the generated report
3. Understand spot price manipulation
4. Learn about TWAP

### Intermediate
1. Create your own LP oracle
2. Write tests for it
3. Run all analyzers
4. Fix found vulnerabilities

### Advanced
1. Write custom Echidna properties
2. Create complex attack scenarios
3. Contribute new detectors
4. Audit other protocols

---

## 🤝 Contributing

Found a new vulnerability pattern? Want to add support for more protocols?

1. Fork the repository
2. Create your feature branch
3. Add tests and documentation
4. Submit pull request

---

## 📞 Support

- **Issues:** https://github.com/arp123-456/alpha-homora-security-tests/issues
- **Discussions:** https://github.com/arp123-456/alpha-homora-security-tests/discussions
- **Documentation:** https://github.com/arp123-456/alpha-homora-security-tests/wiki

---

**Happy Security Testing! 🔒**