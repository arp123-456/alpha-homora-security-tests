#!/bin/bash

set -e

echo "🚀 Setting up LP Oracle Security Scanner..."
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get install -y curl git build-essential jq wget

# Install Foundry
echo "🔨 Installing Foundry..."
if ! command -v forge &> /dev/null; then
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
    echo "✅ Foundry installed"
else
    echo "✅ Foundry already installed"
fi

# Install Rust (required for some tools)
echo "🦀 Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "✅ Rust installed"
else
    echo "✅ Rust already installed"
fi

# Install Python dependencies
echo "🐍 Installing Python tools..."
pip3 install --upgrade pip
pip3 install slither-analyzer
pip3 install mythril
pip3 install manticore[native]
echo "✅ Python tools installed"

# Install Echidna
echo "🦔 Installing Echidna..."
if ! command -v echidna-test &> /dev/null; then
    wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.tar.gz
    tar -xzf echidna-2.2.1-Linux.tar.gz
    sudo mv echidna /usr/local/bin/
    rm echidna-2.2.1-Linux.tar.gz
    echo "✅ Echidna installed"
else
    echo "✅ Echidna already installed"
fi

# Install Aderyn (Rust-based analyzer)
echo "🔍 Installing Aderyn..."
if ! command -v aderyn &> /dev/null; then
    cargo install aderyn
    echo "✅ Aderyn installed"
else
    echo "✅ Aderyn already installed"
fi

# Install Halmos (Symbolic testing)
echo "🎭 Installing Halmos..."
pip3 install halmos
echo "✅ Halmos installed"

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
if [ -f "package.json" ]; then
    npm install
    echo "✅ Node.js dependencies installed"
fi

# Install Foundry dependencies
echo "📚 Installing Foundry dependencies..."
if [ -f "foundry.toml" ]; then
    forge install
    echo "✅ Foundry dependencies installed"
fi

# Setup directories
echo "📁 Creating directories..."
mkdir -p reports
mkdir -p corpus
mkdir -p test/fuzzing
mkdir -p scripts
echo "✅ Directories created"

# Verify installations
echo ""
echo "🔍 Verifying installations..."
echo "Foundry version: $(forge --version)"
echo "Slither version: $(slither --version)"
echo "Echidna version: $(echidna-test --version)"
echo "Python version: $(python3 --version)"
echo "Node version: $(node --version)"

echo ""
echo "✅ Setup complete! You can now run:"
echo "   make test          - Run all tests"
echo "   make scan-all      - Scan all protocols"
echo "   make analyze       - Run static analysis"
echo ""