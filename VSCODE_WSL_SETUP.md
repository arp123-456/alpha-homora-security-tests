# 🚀 VS Code + WSL Setup Guide - LP Oracle Security Scanner

## Complete Installation Guide for Windows Users

This guide will help you set up a complete security testing environment in VS Code using WSL (Windows Subsystem for Linux).

---

## 📋 Prerequisites

- Windows 10/11 (64-bit)
- Administrator access
- At least 8GB RAM
- 20GB free disk space
- Stable internet connection

---

## 🔧 Step 1: Install WSL2

### Option A: Automatic Installation (Recommended)

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Install WSL2 with Ubuntu**
   ```powershell
   wsl --install
   ```

3. **Restart your computer** when prompted

4. **Set up Ubuntu**
   - After restart, Ubuntu will open automatically
   - Create a username (lowercase, no spaces)
   - Create a password (you won't see it as you type)

### Option B: Manual Installation

If automatic installation fails:

1. **Enable WSL**
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

2. **Enable Virtual Machine Platform**
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. **Restart your computer**

4. **Download and install WSL2 kernel update**
   - Download: https://aka.ms/wsl2kernel
   - Run the installer

5. **Set WSL2 as default**
   ```powershell
   wsl --set-default-version 2
   ```

6. **Install Ubuntu from Microsoft Store**
   - Open Microsoft Store
   - Search "Ubuntu 22.04 LTS"
   - Click "Get" and "Install"

### Verify WSL Installation

```powershell
wsl --list --verbose
```

Expected output:
```
  NAME            STATE           VERSION
* Ubuntu-22.04    Running         2
```

---

## 🎨 Step 2: Install VS Code

### Download and Install

1. **Download VS Code**
   - Go to: https://code.visualstudio.com/
   - Click "Download for Windows"
   - Run the installer

2. **Install Required Extensions**
   - Open VS Code
   - Press `Ctrl + Shift + X` to open Extensions
   - Install these extensions:
     - **WSL** (by Microsoft)
     - **Solidity** (by Juan Blanco)
     - **Solidity Visual Developer** (by tintinweb)
     - **Hardhat Solidity** (by Nomic Foundation)
     - **GitLens** (by GitKraken)
     - **Error Lens** (by Alexander)

### Connect VS Code to WSL

1. **Open VS Code**
2. **Press `F1`** or `Ctrl + Shift + P`
3. **Type:** `WSL: Connect to WSL`
4. **Select:** Ubuntu-22.04

You should see "WSL: Ubuntu-22.04" in the bottom-left corner of VS Code.

---

## 🛠️ Step 3: Install Development Tools in WSL

### Open WSL Terminal in VS Code

1. **Press `` Ctrl + ` `` to open terminal**
2. **Verify you're in WSL:**
   ```bash
   uname -a
   ```
   Should show "Linux"

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Install Essential Tools

```bash
# Install build essentials
sudo apt install -y build-essential curl git wget

# Install Python and pip
sudo apt install -y python3 python3-pip

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installations
gcc --version
python3 --version
node --version
npm --version
```

---

## 🔨 Step 4: Install Foundry

### Install Foundry

```bash
# Download and install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Add Foundry to PATH
source ~/.bashrc

# Install Foundry tools
foundryup
```

### Verify Foundry Installation

```bash
forge --version
cast --version
anvil --version
chisel --version
```

Expected output:
```
forge 0.2.0 (...)
cast 0.2.0 (...)
anvil 0.2.0 (...)
chisel 0.2.0 (...)
```

---

## 🦔 Step 5: Install Echidna

### Install Echidna

```bash
# Download Echidna
wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz

# Extract
tar -xzf echidna-2.2.1-Linux.tar.gz

# Move to bin
sudo mv echidna /usr/local/bin/

# Clean up
rm echidna-2.2.1-Linux.tar.gz

# Verify installation
echidna-test --version
```

---

## 🐍 Step 6: Install Slither

### Install Slither

```bash
# Install Slither
pip3 install slither-analyzer

# Verify installation
slither --version
```

### Install solc-select (for Solidity version management)

```bash
pip3 install solc-select

# Install Solidity 0.8.20
solc-select install 0.8.20
solc-select use 0.8.20

# Verify
solc --version
```

---

## 🔮 Step 7: Install Mythril

### Install Mythril

```bash
# Install Mythril
pip3 install mythril

# Verify installation
myth version
```

---

## 🦀 Step 8: Install Rust and Aderyn

### Install Rust

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Source cargo
source "$HOME/.cargo/env"

# Verify
rustc --version
cargo --version
```

### Install Aderyn

```bash
# Install Aderyn
cargo install aderyn

# Verify
aderyn --version
```

---

## 📦 Step 9: Clone and Setup Repository

### Clone Repository

```bash
# Navigate to home directory
cd ~

# Clone repository
git clone https://github.com/arp123-456/alpha-homora-security-tests.git

# Navigate to project
cd alpha-homora-security-tests
```

### Install Project Dependencies

```bash
# Install Foundry dependencies
forge install

# Install Node.js dependencies (if package.json exists)
npm install

# Make scripts executable
chmod +x .devcontainer/setup.sh
chmod +x scripts/*.sh
```

### Create Environment File

```bash
# Copy example env file
cp .env.example .env

# Edit with your RPC URLs
nano .env
```

Add your RPC URLs:
```bash
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

---

## 🎯 Step 10: Run Your First Scan

### Open Project in VS Code

```bash
# Open current directory in VS Code
code .
```

### Run Tests

1. **Open Terminal in VS Code** (`` Ctrl + ` ``)

2. **Run all tests:**
   ```bash
   make test
   ```

3. **Run specific protocol scan:**
   ```bash
   make scan-uniswap-v2
   ```

4. **Run Slither analysis:**
   ```bash
   make slither
   ```

5. **Run Echidna fuzzing:**
   ```bash
   make fuzz-echidna
   ```

---

## 📊 Step 11: View Results

### Test Results

After running `make test`, you'll see output like:

```
Running 15 tests for test/UniswapV2Oracle.t.sol:UniswapV2OracleTest

[PASS] testTWAPProtection() (gas: 345678)
[FAIL] testSpotPriceWithoutProtection() (gas: 123456)
  Error: Price deviation too high
  
Test result: FAILED. 14 passed; 1 failed
```

### Slither Results

After running `make slither`:

```
INFO:Slither:. analyzed (42 contracts)

UniswapV2Oracle.getPrice() uses dangerous spot price
HIGH: Spot price manipulation detected
MEDIUM: Missing TWAP implementation

3 vulnerabilities found
```

### Echidna Results

After running `make fuzz-echidna`:

```
echidna-test: Running 50000 tests...

echidna_test_price_manipulation: failed!
  Counterexample found in 12345 tests
  
1 property violation found
```

### View Reports

```bash
# View generated reports
ls reports/

# View summary
cat reports/summary.md

# Open HTML report (if generated)
explorer.exe reports/index.html
```

---

## 🔍 Step 12: Test Specific Vulnerabilities

### Test Spot Price Manipulation

```bash
make test-spot-price
```

**What it tests:**
- Flash loan attacks on LP pricing
- Single-block price manipulation
- Oracle deviation limits

### Test Flash Loan Attacks

```bash
make test-flash-loan
```

**What it tests:**
- 2000 ETH flash loan scenarios
- ALPHA token flash loans
- Multi-step manipulation

### Test Reentrancy

```bash
make test-reentrancy
```

**What it tests:**
- Read-only reentrancy
- Cross-function reentrancy
- Callback manipulation

### Test Donation Attacks

```bash
make test-donation
```

**What it tests:**
- Direct token transfers
- LP token price inflation
- Internal accounting bypass

---

## 🎨 Step 13: Create Your Own Test

### Create Contract

```bash
# Create new contract
cat > src/MyLPOracle.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MyLPOracle {
    IUniswapV2Pair public pair;
    
    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
    }
    
    function getPrice() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return (uint256(reserve0) * 1e18) / uint256(reserve1);
    }
}
EOF
```

### Create Test

```bash
# Create test file
cat > test/MyLPOracle.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
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
EOF
```

### Run Your Test

```bash
# Compile
forge build

# Run test
forge test --match-contract MyLPOracle -vvv

# Run Slither
slither src/MyLPOracle.sol

# Run Echidna
echidna-test src/MyLPOracle.sol --contract MyLPOracle
```

---

## 🐛 Troubleshooting

### Issue: "forge: command not found"

**Solution:**
```bash
# Reinstall Foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Issue: "echidna-test: command not found"

**Solution:**
```bash
# Check if echidna is in PATH
which echidna

# If not found, reinstall
wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz
tar -xzf echidna-2.2.1-Linux.tar.gz
sudo mv echidna /usr/local/bin/
```

### Issue: "slither: command not found"

**Solution:**
```bash
# Reinstall Slither
pip3 install --upgrade slither-analyzer

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Permission denied" when running scripts

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x .devcontainer/setup.sh
```

### Issue: VS Code can't find WSL

**Solution:**
1. Restart VS Code
2. Press `F1`
3. Type: `WSL: Reopen Folder in WSL`
4. Select your project folder

### Issue: Out of memory during fuzzing

**Solution:**
```bash
# Reduce fuzz runs
forge test --fuzz-runs 1000

# Or edit foundry.toml
nano foundry.toml
# Change fuzz_runs = 10000 to fuzz_runs = 1000
```

---

## 📚 Useful Commands

### Foundry Commands

```bash
# Build contracts
forge build

# Run tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test
forge test --match-test testSpotPrice

# Run tests for specific contract
forge test --match-contract UniswapV2Oracle

# Generate gas report
forge test --gas-report

# Generate coverage
forge coverage

# Format code
forge fmt

# Start local node
anvil
```

### Echidna Commands

```bash
# Basic fuzzing
echidna-test src/Contract.sol --contract ContractName

# With config
echidna-test src/Contract.sol --contract ContractName --config echidna.yaml

# Increase test limit
echidna-test src/Contract.sol --contract ContractName --test-limit 100000

# Generate coverage
echidna-test src/Contract.sol --contract ContractName --coverage
```

### Slither Commands

```bash
# Basic analysis
slither .

# Specific contract
slither src/Contract.sol

# With config
slither . --config-file slither.config.json

# Specific detectors
slither . --detect reentrancy-eth,price-manipulation

# Generate report
slither . --json reports/slither.json

# Print human summary
slither . --print human-summary
```

### Git Commands

```bash
# Check status
git status

# Pull latest changes
git pull

# Create branch
git checkout -b my-feature

# Commit changes
git add .
git commit -m "Add my feature"

# Push changes
git push origin my-feature
```

---

## 🎯 Quick Reference

### Project Structure

```
alpha-homora-security-tests/
├── src/                    # Smart contracts
│   ├── AlphaToken.sol
│   ├── ProxyOracle.sol
│   └── HomoraBankV2.sol
├── test/                   # Test files
│   ├── OracleManipulation.test.js
│   └── RealisticFlashLoan.test.js
├── scripts/                # Utility scripts
├── reports/                # Generated reports
├── foundry.toml           # Foundry config
├── echidna.yaml           # Echidna config
├── slither.config.json    # Slither config
└── Makefile               # Build commands
```

### Common Workflows

#### Workflow 1: Test New Contract
```bash
1. Create contract in src/
2. Create test in test/
3. forge build
4. forge test --match-contract YourContract -vvv
5. slither src/YourContract.sol
6. echidna-test src/YourContract.sol --contract YourContract
```

#### Workflow 2: Full Security Audit
```bash
1. make test
2. make analyze
3. make fuzz-echidna
4. make report
5. Review reports/ directory
```

#### Workflow 3: Fix Vulnerability
```bash
1. Identify issue in reports
2. Edit contract in src/
3. forge test --match-test testVulnerability
4. Verify fix with make analyze
5. Commit changes
```

---

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] WSL2 installed and running
- [ ] VS Code connected to WSL
- [ ] Foundry installed (`forge --version`)
- [ ] Echidna installed (`echidna-test --version`)
- [ ] Slither installed (`slither --version`)
- [ ] Mythril installed (`myth version`)
- [ ] Aderyn installed (`aderyn --version`)
- [ ] Repository cloned
- [ ] Dependencies installed (`forge install`)
- [ ] Tests run successfully (`make test`)
- [ ] Slither analysis works (`make slither`)
- [ ] Echidna fuzzing works (`make fuzz-echidna`)

---

## 🎓 Next Steps

### Beginner
1. Run `make scan-uniswap-v2`
2. Read generated reports
3. Understand vulnerabilities
4. Learn about TWAP

### Intermediate
1. Create your own LP oracle
2. Write comprehensive tests
3. Run all analyzers
4. Fix found vulnerabilities

### Advanced
1. Write custom Echidna properties
2. Create complex attack scenarios
3. Contribute new detectors
4. Audit other protocols

---

## 📞 Support

- **Issues:** https://github.com/arp123-456/alpha-homora-security-tests/issues
- **Discussions:** https://github.com/arp123-456/alpha-homora-security-tests/discussions
- **Documentation:** https://github.com/arp123-456/alpha-homora-security-tests/wiki

---

## 🎉 You're Ready!

Your complete security testing environment is now set up. Start scanning for vulnerabilities:

```bash
make scan-all
```

**Happy Security Testing! 🔒**