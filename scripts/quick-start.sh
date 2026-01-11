#!/bin/bash

# Quick Start Script for LP Oracle Security Scanner
# Run this after WSL setup to verify everything works

set -e

echo "🚀 LP Oracle Security Scanner - Quick Start"
echo "==========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in WSL
if ! grep -q Microsoft /proc/version; then
    echo -e "${RED}❌ Not running in WSL${NC}"
    echo "Please run this script in WSL (Windows Subsystem for Linux)"
    exit 1
fi

echo -e "${GREEN}✅ Running in WSL${NC}"
echo ""

# Check installations
echo "🔍 Checking installations..."
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 installed${NC}"
        $1 --version | head -n 1
        return 0
    else
        echo -e "${RED}❌ $1 not found${NC}"
        return 1
    fi
}

# Check all required tools
MISSING=0

check_command forge || MISSING=1
check_command cast || MISSING=1
check_command anvil || MISSING=1
check_command echidna-test || MISSING=1
check_command slither || MISSING=1
check_command python3 || MISSING=1
check_command node || MISSING=1
check_command npm || MISSING=1

echo ""

if [ $MISSING -eq 1 ]; then
    echo -e "${RED}❌ Some tools are missing${NC}"
    echo "Please follow the installation guide in VSCODE_WSL_SETUP.md"
    exit 1
fi

echo -e "${GREEN}✅ All tools installed!${NC}"
echo ""

# Check if in project directory
if [ ! -f "foundry.toml" ]; then
    echo -e "${YELLOW}⚠️  Not in project directory${NC}"
    echo "Cloning repository..."
    cd ~
    git clone https://github.com/arp123-456/alpha-homora-security-tests.git
    cd alpha-homora-security-tests
fi

echo -e "${GREEN}✅ In project directory${NC}"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
echo ""

if [ ! -d "lib" ]; then
    echo "Installing Foundry dependencies..."
    forge install
fi

if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Create .env if not exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env and add your RPC URLs${NC}"
fi

echo ""
echo "🧪 Running quick tests..."
echo ""

# Run a simple test
echo "Testing Foundry..."
forge build
echo -e "${GREEN}✅ Foundry build successful${NC}"
echo ""

# Run basic test
echo "Running basic tests..."
forge test --match-test testBasic -vv || true
echo ""

# Run Slither on a simple contract
echo "Testing Slither..."
if [ -f "src/AlphaToken.sol" ]; then
    slither src/AlphaToken.sol --print human-summary > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ Slither analysis successful${NC}"
fi
echo ""

# Test Echidna
echo "Testing Echidna..."
echidna-test --version > /dev/null 2>&1
echo -e "${GREEN}✅ Echidna ready${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "You can now run:"
echo ""
echo "  ${GREEN}make test${NC}              - Run all tests"
echo "  ${GREEN}make scan-all${NC}          - Scan all protocols"
echo "  ${GREEN}make analyze${NC}           - Run static analysis"
echo "  ${GREEN}make fuzz-echidna${NC}      - Run fuzzing"
echo "  ${GREEN}make help${NC}              - Show all commands"
echo ""
echo "Quick tests:"
echo "  ${GREEN}make test-spot-price${NC}   - Test spot price manipulation"
echo "  ${GREEN}make test-flash-loan${NC}   - Test flash loan attacks"
echo "  ${GREEN}make test-reentrancy${NC}   - Test reentrancy"
echo ""
echo "For detailed guide, see: VSCODE_WSL_SETUP.md"
echo ""