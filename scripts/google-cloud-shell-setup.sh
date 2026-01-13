#!/bin/bash

#############################################################################
# LP Oracle Security Scanner - Google Cloud Shell Setup
# Complete installation script with error handling
#############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Error handler
error_exit() {
    print_error "$1"
    exit 1
}

#############################################################################
# STEP 1: System Check
#############################################################################

print_header "STEP 1: Checking System Requirements"

# Check if running in Cloud Shell
if [ ! -d "/google/devshell" ]; then
    print_warning "Not running in Google Cloud Shell"
    print_info "This script is optimized for Google Cloud Shell but will try to continue..."
fi

# Check available disk space
AVAILABLE_SPACE=$(df -h $HOME | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$AVAILABLE_SPACE < 2" | bc -l) )); then
    error_exit "Insufficient disk space. Need at least 2GB free."
fi

print_success "System check passed"
print_info "Available disk space: ${AVAILABLE_SPACE}GB"

#############################################################################
# STEP 2: Update System
#############################################################################

print_header "STEP 2: Updating System Packages"

sudo apt-get update -qq || error_exit "Failed to update package list"
sudo apt-get install -y -qq \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    jq \
    wget \
    unzip \
    python3 \
    python3-pip \
    || error_exit "Failed to install system packages"

print_success "System packages updated"

#############################################################################
# STEP 3: Install Foundry
#############################################################################

print_header "STEP 3: Installing Foundry"

# Check if Foundry is already installed
if command -v forge &> /dev/null; then
    print_info "Foundry already installed, updating..."
    foundryup || print_warning "Foundry update failed, will reinstall"
fi

# Install Foundry
if ! command -v forge &> /dev/null; then
    print_info "Installing Foundry..."
    
    # Download and install
    curl -L https://foundry.paradigm.xyz -o foundry-install.sh || error_exit "Failed to download Foundry installer"
    chmod +x foundry-install.sh
    bash foundry-install.sh || error_exit "Failed to install Foundry"
    rm foundry-install.sh
    
    # Add to PATH
    export PATH="$HOME/.foundry/bin:$PATH"
    
    # Add to bashrc for persistence
    if ! grep -q "foundry/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
    fi
    
    # Run foundryup
    source ~/.bashrc
    foundryup || error_exit "Failed to run foundryup"
fi

# Verify installation
if ! command -v forge &> /dev/null; then
    error_exit "Foundry installation failed"
fi

FORGE_VERSION=$(forge --version | head -n 1)
print_success "Foundry installed: $FORGE_VERSION"

#############################################################################
# STEP 4: Install Rust (for Aderyn)
#############################################################################

print_header "STEP 4: Installing Rust"

# Check if Rust is already installed
if command -v cargo &> /dev/null; then
    print_info "Rust already installed"
    RUST_VERSION=$(rustc --version)
    print_success "$RUST_VERSION"
else
    print_info "Installing Rust..."
    
    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rust-install.sh || error_exit "Failed to download Rust installer"
    chmod +x rust-install.sh
    sh rust-install.sh -y || error_exit "Failed to install Rust"
    rm rust-install.sh
    
    # Source cargo env
    source "$HOME/.cargo/env"
    
    # Add to bashrc
    if ! grep -q "cargo/env" ~/.bashrc; then
        echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
    fi
    
    RUST_VERSION=$(rustc --version)
    print_success "Rust installed: $RUST_VERSION"
fi

#############################################################################
# STEP 5: Install Python Tools
#############################################################################

print_header "STEP 5: Installing Python Security Tools"

# Upgrade pip
print_info "Upgrading pip..."
python3 -m pip install --upgrade pip --quiet || print_warning "pip upgrade failed"

# Install solc-select first
print_info "Installing solc-select..."
pip3 install solc-select --quiet || error_exit "Failed to install solc-select"

# Install and use Solidity 0.8.20
print_info "Installing Solidity 0.8.20..."
solc-select install 0.8.20 || print_warning "Solidity installation failed"
solc-select use 0.8.20 || print_warning "Solidity selection failed"

# Install Slither
print_info "Installing Slither..."
pip3 install slither-analyzer --quiet || error_exit "Failed to install Slither"

# Install Mythril (optional, can be slow)
print_info "Installing Mythril (this may take a few minutes)..."
pip3 install mythril --quiet || print_warning "Mythril installation failed (optional)"

# Verify installations
if command -v slither &> /dev/null; then
    SLITHER_VERSION=$(slither --version 2>&1 | head -n 1)
    print_success "Slither installed: $SLITHER_VERSION"
else
    print_warning "Slither installation verification failed"
fi

#############################################################################
# STEP 6: Install Echidna
#############################################################################

print_header "STEP 6: Installing Echidna"

# Check if Echidna is already installed
if command -v echidna-test &> /dev/null; then
    print_info "Echidna already installed"
    ECHIDNA_VERSION=$(echidna-test --version)
    print_success "$ECHIDNA_VERSION"
else
    print_info "Installing Echidna..."
    
    # Download Echidna
    ECHIDNA_VERSION="2.2.1"
    wget -q https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-${ECHIDNA_VERSION}-Linux.tar.gz \
        || error_exit "Failed to download Echidna"
    
    # Extract
    tar -xzf echidna-${ECHIDNA_VERSION}-Linux.tar.gz || error_exit "Failed to extract Echidna"
    
    # Move to bin
    sudo mv echidna /usr/local/bin/ || error_exit "Failed to install Echidna"
    
    # Cleanup
    rm echidna-${ECHIDNA_VERSION}-Linux.tar.gz
    
    # Verify
    if command -v echidna-test &> /dev/null; then
        ECHIDNA_VERSION=$(echidna-test --version)
        print_success "Echidna installed: $ECHIDNA_VERSION"
    else
        print_warning "Echidna installation verification failed"
    fi
fi

#############################################################################
# STEP 7: Install Aderyn (Optional)
#############################################################################

print_header "STEP 7: Installing Aderyn (Optional)"

print_info "Installing Aderyn (this may take 5-10 minutes)..."
cargo install aderyn --quiet 2>&1 | grep -v "Compiling" || print_warning "Aderyn installation failed (optional)"

if command -v aderyn &> /dev/null; then
    ADERYN_VERSION=$(aderyn --version)
    print_success "Aderyn installed: $ADERYN_VERSION"
else
    print_warning "Aderyn not installed (optional tool)"
fi

#############################################################################
# STEP 8: Clone Repository
#############################################################################

print_header "STEP 8: Cloning Repository"

# Remove existing directory if it exists
if [ -d "alpha-homora-security-tests" ]; then
    print_warning "Repository already exists, removing..."
    rm -rf alpha-homora-security-tests
fi

# Clone repository
print_info "Cloning repository..."
git clone https://github.com/arp123-456/alpha-homora-security-tests.git \
    || error_exit "Failed to clone repository"

cd alpha-homora-security-tests || error_exit "Failed to enter repository directory"

print_success "Repository cloned successfully"

#############################################################################
# STEP 9: Install Project Dependencies
#############################################################################

print_header "STEP 9: Installing Project Dependencies"

# Install Foundry dependencies
print_info "Installing Foundry dependencies..."
forge install --no-commit || error_exit "Failed to install Foundry dependencies"

# Install Node.js dependencies if package.json exists
if [ -f "package.json" ]; then
    print_info "Installing Node.js dependencies..."
    npm install --silent || print_warning "npm install failed (optional)"
fi

print_success "Project dependencies installed"

#############################################################################
# STEP 10: Setup Environment
#############################################################################

print_header "STEP 10: Setting Up Environment"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_info "Creating .env file..."
    cp .env.example .env || print_warning ".env.example not found"
    print_warning "Please edit .env and add your RPC URLs if needed"
fi

# Make scripts executable
if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
fi

print_success "Environment setup complete"

#############################################################################
# STEP 11: Verify Installation
#############################################################################

print_header "STEP 11: Verifying Installation"

echo ""
print_info "Installed Tools:"
echo ""

# Foundry
if command -v forge &> /dev/null; then
    echo "  ✅ Foundry: $(forge --version | head -n 1)"
else
    echo "  ❌ Foundry: Not found"
fi

# Slither
if command -v slither &> /dev/null; then
    echo "  ✅ Slither: $(slither --version 2>&1 | head -n 1)"
else
    echo "  ❌ Slither: Not found"
fi

# Echidna
if command -v echidna-test &> /dev/null; then
    echo "  ✅ Echidna: $(echidna-test --version)"
else
    echo "  ❌ Echidna: Not found"
fi

# Mythril
if command -v myth &> /dev/null; then
    echo "  ✅ Mythril: $(myth version 2>&1 | head -n 1)"
else
    echo "  ⚠️  Mythril: Not installed (optional)"
fi

# Aderyn
if command -v aderyn &> /dev/null; then
    echo "  ✅ Aderyn: $(aderyn --version)"
else
    echo "  ⚠️  Aderyn: Not installed (optional)"
fi

# Rust
if command -v cargo &> /dev/null; then
    echo "  ✅ Rust: $(rustc --version)"
else
    echo "  ❌ Rust: Not found"
fi

# Python
echo "  ✅ Python: $(python3 --version)"

echo ""

#############################################################################
# STEP 12: Build Contracts
#############################################################################

print_header "STEP 12: Building Contracts"

print_info "Compiling contracts..."
forge build || error_exit "Failed to build contracts"

print_success "Contracts compiled successfully"

#############################################################################
# FINAL SUMMARY
#############################################################################

print_header "🎉 INSTALLATION COMPLETE!"

echo ""
print_success "All tools installed and ready to use!"
echo ""
print_info "You can now run:"
echo ""
echo "  ${GREEN}make test${NC}              - Run all tests"
echo "  ${GREEN}make scan-all${NC}          - Scan all protocols"
echo "  ${GREEN}make analyze${NC}           - Run static analysis"
echo "  ${GREEN}make fuzz-echidna${NC}      - Run fuzzing"
echo "  ${GREEN}make test-spot-price${NC}   - Test spot price manipulation"
echo "  ${GREEN}make test-flash-loan${NC}   - Test flash loan attacks"
echo "  ${GREEN}make test-reentrancy${NC}   - Test reentrancy"
echo "  ${GREEN}make help${NC}              - Show all commands"
echo ""
print_info "Current directory: $(pwd)"
echo ""
print_warning "Note: If you close Cloud Shell, you'll need to run this script again"
print_info "To save your work, commit changes to a Git repository"
echo ""

#############################################################################
# OPTIONAL: Run Quick Test
#############################################################################

read -p "Would you like to run a quick test now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_header "Running Quick Test"
    
    print_info "Running basic Foundry tests..."
    forge test --match-test testBasic -vv || print_warning "No basic tests found"
    
    print_info "Running Slither analysis on AlphaToken..."
    if [ -f "src/AlphaToken.sol" ]; then
        slither src/AlphaToken.sol --print human-summary || print_warning "Slither analysis failed"
    fi
    
    print_success "Quick test complete!"
fi

echo ""
print_success "Setup complete! Happy security testing! 🔒"
echo ""