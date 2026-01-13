# 🌥️ Google Cloud Shell - Complete Setup Guide

## Run LP Oracle Security Scanner in Google Cloud Shell

**No installation on your computer needed - everything runs in the cloud!**

---

## 🚀 Quick Start (Copy & Paste)

### Step 1: Open Google Cloud Shell

1. Go to: **https://console.cloud.google.com**
2. Click the **"Activate Cloud Shell"** icon (top right, looks like `>_`)
3. Wait for Cloud Shell to load (~10 seconds)

### Step 2: Run Setup Script (One Command)

Copy and paste this **single command** into Cloud Shell:

```bash
curl -fsSL https://raw.githubusercontent.com/arp123-456/alpha-homora-security-tests/main/scripts/google-cloud-shell-setup.sh | bash
```

**That's it!** The script will:
- ✅ Install all required tools (Foundry, Slither, Echidna, etc.)
- ✅ Clone the repository
- ✅ Install dependencies
- ✅ Build contracts
- ✅ Verify everything works

**Time:** ~5-10 minutes

---

## 📊 What Gets Installed

The script automatically installs:

1. **Foundry** (forge, cast, anvil, chisel)
2. **Slither** (static analyzer)
3. **Echidna** (fuzzer)
4. **Mythril** (symbolic execution)
5. **Aderyn** (Rust analyzer)
6. **Rust** (for Aderyn)
7. **Python tools** (pip, solc-select)
8. **Build tools** (gcc, make, etc.)

---

## 🎯 After Installation

### Run Tests

Once installation completes, you'll be in the project directory. Run:

```bash
# Run all tests
make test

# Scan specific protocol
make scan-uniswap-v2

# Run static analysis
make analyze

# Run fuzzing
make fuzz-echidna

# Generate report
make report
```

### View Results

Results appear directly in the terminal. Example:

```
Running 15 tests for test/UniswapV2Oracle.t.sol

[PASS] testTWAPProtection() (gas: 345678)
[FAIL] testSpotPriceWithoutProtection() (gas: 123456)
  Error: Price deviation too high
  
Test result: FAILED. 14 passed; 1 failed
```

---

## 🔧 Manual Installation (If Script Fails)

If the automated script fails, follow these manual steps:

### Step 1: Update System

```bash
sudo apt-get update
sudo apt-get install -y curl git build-essential pkg-config libssl-dev jq wget python3 python3-pip
```

### Step 2: Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

Verify:
```bash
forge --version
```

### Step 3: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

Verify:
```bash
cargo --version
```

### Step 4: Install Python Tools

```bash
# Install solc-select
pip3 install solc-select

# Install Solidity 0.8.20
solc-select install 0.8.20
solc-select use 0.8.20

# Install Slither
pip3 install slither-analyzer

# Install Mythril (optional)
pip3 install mythril
```

Verify:
```bash
slither --version
```

### Step 5: Install Echidna

```bash
wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz
tar -xzf echidna-2.2.1-Linux.tar.gz
sudo mv echidna /usr/local/bin/
rm echidna-2.2.1-Linux.tar.gz
```

Verify:
```bash
echidna-test --version
```

### Step 6: Install Aderyn (Optional)

```bash
cargo install aderyn
```

This takes 5-10 minutes. You can skip it if you want.

### Step 7: Clone Repository

```bash
cd ~
git clone https://github.com/arp123-456/alpha-homora-security-tests.git
cd alpha-homora-security-tests
```

### Step 8: Install Dependencies

```bash
# Foundry dependencies
forge install

# Node.js dependencies (if needed)
npm install
```

### Step 9: Build Contracts

```bash
forge build
```

### Step 10: Run Tests

```bash
make test
```

---

## 🎨 Example Commands

### Basic Testing

```bash
# Run all tests
make test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testSpotPriceManipulation

# Run tests for specific contract
forge test --match-contract UniswapV2Oracle
```

### Protocol Scanning

```bash
# Scan all protocols
make scan-all

# Scan Uniswap V2
make scan-uniswap-v2

# Scan Curve
make scan-curve

# Scan Balancer
make scan-balancer
```

### Security Analysis

```bash
# Run all analyzers
make analyze

# Slither only
make slither

# Mythril only
make mythril

# Aderyn only (if installed)
aderyn .
```

### Fuzzing

```bash
# Basic fuzzing (50K runs)
make fuzz-echidna

# Intense fuzzing (100K runs)
make fuzz-echidna-intense

# Foundry fuzzing
forge test --fuzz-runs 10000
```

### Specific Vulnerability Tests

```bash
# Spot price manipulation
make test-spot-price

# Flash loan attacks
make test-flash-loan

# Reentrancy
make test-reentrancy

# Donation attacks
make test-donation
```

### Reports

```bash
# Generate comprehensive report
make report

# Coverage report
make test-coverage

# Gas report
make test-gas
```

---

## 📊 Expected Output

### Successful Installation

```
========================================
🎉 INSTALLATION COMPLETE!
========================================

✅ All tools installed and ready to use!

You can now run:

  make test              - Run all tests
  make scan-all          - Scan all protocols
  make analyze           - Run static analysis
  make fuzz-echidna      - Run fuzzing
  make help              - Show all commands

Current directory: /home/user/alpha-homora-security-tests
```

### Test Results

```
Running 15 tests for test/UniswapV2Oracle.t.sol:UniswapV2OracleTest

[PASS] testTWAPProtection() (gas: 345678)
[FAIL] testSpotPriceWithoutProtection() (gas: 123456)
  Error: Price deviation too high
  Expected: 10000
  Actual: 60000
  
[PASS] testReentrancyGuard() (gas: 234567)

Test result: FAILED. 14 passed; 1 failed
```

### Slither Analysis

```
INFO:Slither:. analyzed (42 contracts)

UniswapV2Oracle.getPrice() (src/UniswapV2Oracle.sol#45-52) uses dangerous spot price:
  - price = (reserve0 * 1e18) / reserve1 (line 48)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#price-manipulation

HIGH: Spot price manipulation detected
MEDIUM: Missing TWAP implementation
LOW: Centralized oracle control

3 vulnerabilities found
```

---

## 🐛 Troubleshooting

### Issue: "Permission denied"

**Solution:**
```bash
chmod +x scripts/*.sh
```

### Issue: "forge: command not found"

**Solution:**
```bash
export PATH="$HOME/.foundry/bin:$PATH"
source ~/.bashrc
foundryup
```

### Issue: "slither: command not found"

**Solution:**
```bash
export PATH="$HOME/.local/bin:$PATH"
pip3 install --user slither-analyzer
```

### Issue: "Out of disk space"

**Solution:**
```bash
# Clean build artifacts
make clean

# Remove unused files
rm -rf ~/.cache/pip
```

### Issue: "echidna-test: command not found"

**Solution:**
```bash
# Check if echidna is in /usr/local/bin
ls -la /usr/local/bin/echidna

# If not, reinstall
wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz
tar -xzf echidna-2.2.1-Linux.tar.gz
sudo mv echidna /usr/local/bin/
```

### Issue: "Failed to build contracts"

**Solution:**
```bash
# Clean and rebuild
forge clean
forge install
forge build
```

### Issue: Cloud Shell disconnected

**Solution:**
Cloud Shell sessions timeout after inactivity. Your files are saved, but you need to:

1. Reopen Cloud Shell
2. Navigate to project: `cd alpha-homora-security-tests`
3. Re-export PATH: `export PATH="$HOME/.foundry/bin:$PATH"`
4. Continue working

---

## 💾 Saving Your Work

### Option 1: Commit to Git

```bash
# Configure git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# Create branch
git checkout -b my-changes

# Commit changes
git add .
git commit -m "My security tests"

# Push to your fork
git push origin my-changes
```

### Option 2: Download Files

```bash
# Download specific file
cloudshell download reports/summary.md

# Create archive
tar -czf my-reports.tar.gz reports/
cloudshell download my-reports.tar.gz
```

### Option 3: Upload to Cloud Storage

```bash
# Upload to Google Cloud Storage (if you have a bucket)
gsutil cp -r reports/ gs://your-bucket/security-reports/
```

---

## 🔄 Restarting After Session Timeout

If your Cloud Shell session times out:

```bash
# Navigate to project
cd alpha-homora-security-tests

# Re-export PATH
export PATH="$HOME/.foundry/bin:$PATH"
source "$HOME/.cargo/env"

# Continue working
make test
```

Or run the setup script again (it will skip already installed tools):

```bash
curl -fsSL https://raw.githubusercontent.com/arp123-456/alpha-homora-security-tests/main/scripts/google-cloud-shell-setup.sh | bash
```

---

## 📈 Performance Tips

### Speed Up Tests

```bash
# Run tests in parallel
forge test --jobs 4

# Skip slow tests
forge test --no-match-test testSlow

# Reduce fuzz runs
forge test --fuzz-runs 1000
```

### Reduce Memory Usage

```bash
# Clean cache
forge clean

# Limit parallel jobs
forge test --jobs 1
```

---

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] `forge --version` shows version
- [ ] `slither --version` shows version
- [ ] `echidna-test --version` shows version
- [ ] `make test` runs successfully
- [ ] `make analyze` completes
- [ ] Reports generated in `reports/`

---

## 🎓 Next Steps

### Beginner

1. Run `make scan-uniswap-v2`
2. Read generated reports
3. Understand vulnerabilities
4. Learn about TWAP

### Intermediate

1. Modify test parameters
2. Add custom tests
3. Run comprehensive scans
4. Generate detailed reports

### Advanced

1. Create custom contracts
2. Write new test suites
3. Add custom Echidna properties
4. Contribute improvements

---

## 📚 Additional Resources

- **Repository:** https://github.com/arp123-456/alpha-homora-security-tests
- **Foundry Book:** https://book.getfoundry.sh/
- **Slither Docs:** https://github.com/crytic/slither
- **Echidna Tutorial:** https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna

---

## 🎉 You're Ready!

**Everything is set up and ready to run in Google Cloud Shell!**

**Quick Start:**
```bash
curl -fsSL https://raw.githubusercontent.com/arp123-456/alpha-homora-security-tests/main/scripts/google-cloud-shell-setup.sh | bash
```

**Then run:**
```bash
make scan-all
```

**Happy Security Testing! 🔒**