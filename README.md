# 🔒 LP Token Oracle Manipulation Security Scanner

## Comprehensive Security Analysis for LP Tokens Across DeFi Protocols

**Detect spot price manipulation, flash loan attacks, reentrancy, and donation attacks in LP token oracles.**

---

## 🚀 **FASTEST WAY TO START (1 Command)**

### Google Cloud Shell (Completely Free, No Setup)

1. **Open:** https://console.cloud.google.com
2. **Click:** Activate Cloud Shell icon (top right)
3. **Paste this ONE command:**

```bash
curl -fsSL https://raw.githubusercontent.com/arp123-456/alpha-homora-security-tests/main/scripts/google-cloud-shell-setup.sh | bash
```

**Done!** In 5-10 minutes you'll have a complete security testing environment.

Then run:
```bash
make scan-all
```

---

## 🎯 Three Ways to Get Started

### Option 1: Google Cloud Shell ⭐ (Easiest - 1 Command)

**Perfect for:** Quick testing, no account limits, completely free

**Setup:** Copy-paste one command (above)  
**Time:** 5-10 minutes  
**Cost:** FREE (unlimited)

**Guide:** [GOOGLE_CLOUD_SHELL_GUIDE.md](./GOOGLE_CLOUD_SHELL_GUIDE.md)

---

### Option 2: GitHub Actions ⭐⭐⭐ (Automated CI/CD)

**Perfect for:** Continuous testing, automation, team collaboration

**Setup:**
1. Fork this repository
2. Go to Actions tab
3. Click "Run workflow"
4. Download reports

**Time:** 10 minutes (automated)  
**Cost:** FREE (2000 minutes/month)

**Guide:** [CLOUD_TESTING_GUIDE.md](./CLOUD_TESTING_GUIDE.md)

---

### Option 3: GitHub Codespaces ⭐⭐ (Interactive Development)

**Perfect for:** Development, debugging, learning

**Setup:**
1. Click "Code" → "Codespaces"
2. Create codespace
3. Wait for auto-setup
4. Run `make scan-all`

**Time:** 5 minutes  
**Cost:** FREE (60 hours/month)

**Guide:** [CODESPACES_GUIDE.md](./CODESPACES_GUIDE.md)

---

### Option 4: Local Setup (VS Code + WSL)

**Perfect for:** Windows users, full control

**Guide:** [VSCODE_WSL_SETUP.md](./VSCODE_WSL_SETUP.md)

---

## 🔍 What Gets Tested

### Vulnerabilities Detected:

1. **Spot Price Manipulation** 🔴 CRITICAL
   - Flash loan attacks on LP pricing
   - Single-block price manipulation
   - Oracle deviation limit bypass

2. **Read-Only Reentrancy** 🟠 HIGH
   - Callback exploitation during price reads
   - State manipulation attacks
   - Cross-function reentrancy

3. **Flash Loan Exploits** 🟠 HIGH
   - 2000 ETH flash loan scenarios
   - ALPHA token flash loans
   - Multi-step manipulation

4. **Donation Attacks** 🟡 MEDIUM
   - Direct token transfers to pools
   - LP token price inflation
   - Internal accounting bypass

5. **Missing TWAP** 🟡 MEDIUM
   - No time-weighted average
   - Vulnerable to flash loans

### Protocols Scanned:

- ✅ Uniswap V2
- ✅ Uniswap V3
- ✅ Curve Finance
- ✅ Balancer
- ✅ SushiSwap
- ✅ PancakeSwap
- ✅ Alpha Homora
- ✅ Custom implementations

---

## 🛠️ Tools Included

### Static Analysis
- **Slither** - 40+ vulnerability detectors
- **Mythril** - Symbolic execution
- **Aderyn** - Rust-based analyzer

### Fuzzing
- **Echidna** - 50,000+ test runs
- **Foundry Fuzz** - Property-based testing

### Testing
- **Foundry** - Fast Solidity testing
- **Hardhat** - Ethereum development

---

## 📊 Quick Commands

### After Setup (Google Cloud Shell / Codespaces / Local)

```bash
# Run all tests
make test

# Scan specific protocol
make scan-uniswap-v2
make scan-curve
make scan-balancer

# Run static analysis
make analyze

# Run fuzzing
make fuzz-echidna

# Specific vulnerability tests
make test-spot-price
make test-flash-loan
make test-reentrancy
make test-donation

# Generate reports
make report
```

---

## 📈 Example Output

### Foundry Tests
```
Running 15 tests for test/UniswapV2Oracle.t.sol

[PASS] testTWAPProtection() (gas: 345678)
[FAIL] testSpotPriceWithoutProtection() (gas: 123456)
  Error: Price deviation too high
  
Test result: FAILED. 14 passed; 1 failed
```

### Slither Analysis
```
INFO:Slither:. analyzed (42 contracts)

UniswapV2Oracle.getPrice() uses dangerous spot price
HIGH: Spot price manipulation detected
MEDIUM: Missing TWAP implementation

3 vulnerabilities found
```

### Echidna Fuzzing
```
echidna-test: Running 50000 tests...

echidna_test_price_manipulation: failed!
Counterexample found in 12345 tests
```

---

## 🎨 Test Your Own Contract

### Step 1: Create Contract
```solidity
// src/MyLPOracle.sol
pragma solidity ^0.8.20;

contract MyLPOracle {
    function getPrice() external view returns (uint256) {
        // Your implementation
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
    function testSpotPriceManipulation() public {
        // Your test
    }
}
```

### Step 3: Run All Scans
```bash
forge test --match-contract MyLPOracle -vvv
slither src/MyLPOracle.sol
echidna-test src/MyLPOracle.sol --contract MyLPOracle
```

---

## 📚 Complete Documentation

### Setup Guides
- **[GOOGLE_CLOUD_SHELL_GUIDE.md](./GOOGLE_CLOUD_SHELL_GUIDE.md)** - Google Cloud Shell (1 command)
- **[QUICK_START_CLOUD.md](./QUICK_START_CLOUD.md)** - Quick start guide
- **[CLOUD_TESTING_GUIDE.md](./CLOUD_TESTING_GUIDE.md)** - Complete cloud guide
- **[CODESPACES_GUIDE.md](./CODESPACES_GUIDE.md)** - GitHub Codespaces
- **[VSCODE_WSL_SETUP.md](./VSCODE_WSL_SETUP.md)** - VS Code + WSL

### Test Results
- **[LIVE_TEST_RESULTS.md](./LIVE_TEST_RESULTS.md)** - Oracle manipulation tests
- **[REALISTIC_ATTACK_RESULTS.md](./REALISTIC_ATTACK_RESULTS.md)** - Flash loan tests
- **[ALPHA_FINANCE_RISK_ANALYSIS.md](./ALPHA_FINANCE_RISK_ANALYSIS.md)** - Alpha Homora analysis

### Project Info
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Complete overview
- **[CLOUD_TESTING_SUMMARY.md](./CLOUD_TESTING_SUMMARY.md)** - Cloud testing summary

---

## ✅ Security Checklist

Before deploying your LP oracle:

- [ ] Run `make test` - All tests pass
- [ ] Run `make analyze` - No critical issues
- [ ] Run `make fuzz-echidna` - No vulnerabilities
- [ ] Implement TWAP (30+ minute window)
- [ ] Add deviation limits (5% maximum)
- [ ] Add reentrancy guards
- [ ] Use internal accounting
- [ ] Add freshness checks
- [ ] Multi-oracle validation
- [ ] Professional audit
- [ ] Bug bounty program

---

## 🎓 Learning Resources

### Beginner
1. Run `make scan-uniswap-v2`
2. Read generated reports
3. Understand vulnerabilities
4. Learn about TWAP

### Intermediate
1. Create your own LP oracle
2. Write comprehensive tests
3. Run all analyzers
4. Fix vulnerabilities

### Advanced
1. Write custom Echidna properties
2. Create complex attack scenarios
3. Contribute new detectors
4. Audit other protocols

---

## 📊 Real-World Examples

### Vulnerable Protocols (Historical)
- **Cream Finance** - $130M (Oracle manipulation)
- **Alpha Homora** - $37.5M (Rounding error)
- **Inverse Finance** - $15M (TWAP manipulation)
- **Mango Markets** - $110M (Oracle + market manipulation)

### Secure Implementations
- **Chainlink** - Decentralized oracles
- **Uniswap V3 TWAP** - Time-weighted average
- **Compound V3** - Multi-oracle validation

---

## 🤝 Contributing

Found a vulnerability pattern? Want to add support for more protocols?

1. Fork repository
2. Create feature branch
3. Add tests and documentation
4. Submit pull request

---

## 📞 Support

- **Issues:** https://github.com/arp123-456/alpha-homora-security-tests/issues
- **Discussions:** https://github.com/arp123-456/alpha-homora-security-tests/discussions
- **Documentation:** https://github.com/arp123-456/alpha-homora-security-tests/wiki

---

## ⚠️ Disclaimer

**This tool is for security research and educational purposes only. Always conduct responsible security research and disclose vulnerabilities to protocol teams before public disclosure.**

---

## 🎉 Get Started Now!

### Fastest Way (1 Command):

```bash
# Open Google Cloud Shell and run:
curl -fsSL https://raw.githubusercontent.com/arp123-456/alpha-homora-security-tests/main/scripts/google-cloud-shell-setup.sh | bash
```

### Or Use GitHub Actions:

1. Fork this repository
2. Go to Actions tab
3. Click "Run workflow"

### Or Open Codespace:

1. Click "Code" → "Codespaces"
2. Create codespace
3. Run `make scan-all`

---

**Happy Security Testing! 🔒**

**Repository:** https://github.com/arp123-456/alpha-homora-security-tests