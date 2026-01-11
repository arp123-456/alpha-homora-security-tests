.PHONY: all test clean install analyze scan

# Default target
all: install test

# Installation
install:
	@echo "📦 Installing dependencies..."
	forge install
	npm install
	@echo "✅ Dependencies installed"

install-tools:
	@echo "🔧 Installing security tools..."
	pip3 install slither-analyzer mythril manticore halmos
	cargo install aderyn
	@echo "✅ Security tools installed"

# Testing
test:
	@echo "🧪 Running all tests..."
	forge test -vvv

test-gas:
	@echo "⛽ Running gas report..."
	forge test --gas-report

test-coverage:
	@echo "📊 Generating coverage report..."
	forge coverage --report lcov
	genhtml lcov.info -o coverage

test-fuzz:
	@echo "🎲 Running fuzz tests..."
	forge test --fuzz-runs 10000

test-invariant:
	@echo "🔒 Running invariant tests..."
	forge test --match-test invariant

# Echidna fuzzing
fuzz-echidna:
	@echo "🦔 Running Echidna fuzzer..."
	echidna-test src/LPOracle.sol --contract LPOracle --config echidna.yaml

fuzz-echidna-intense:
	@echo "🦔 Running intense Echidna fuzzing..."
	echidna-test src/LPOracle.sol --contract LPOracle --config echidna.yaml --test-limit 100000

# Static analysis
analyze:
	@echo "🔍 Running static analysis..."
	@make slither
	@make mythril
	@make aderyn

slither:
	@echo "🐍 Running Slither..."
	slither . --config-file slither.config.json --json reports/slither.json
	slither . --config-file slither.config.json --print human-summary > reports/slither-summary.txt

mythril:
	@echo "🔮 Running Mythril..."
	myth analyze src/**/*.sol --solc-json mythril-config.json -o json > reports/mythril.json || true

aderyn:
	@echo "🔍 Running Aderyn..."
	aderyn . --output reports/aderyn.md

halmos:
	@echo "🎭 Running Halmos symbolic tests..."
	halmos --function check --solver-timeout-assertion 0

# Protocol scanning
scan-all:
	@echo "🔍 Scanning all protocols..."
	@make scan-uniswap-v2
	@make scan-curve
	@make scan-balancer
	@make scan-sushiswap

scan-uniswap-v2:
	@echo "🦄 Scanning Uniswap V2..."
	forge test --match-contract UniswapV2Oracle -vvv
	@echo "✅ Uniswap V2 scan complete"

scan-curve:
	@echo "🌊 Scanning Curve..."
	forge test --match-contract CurveOracle -vvv
	@echo "✅ Curve scan complete"

scan-balancer:
	@echo "⚖️  Scanning Balancer..."
	forge test --match-contract BalancerOracle -vvv
	@echo "✅ Balancer scan complete"

scan-sushiswap:
	@echo "🍣 Scanning SushiSwap..."
	forge test --match-contract SushiSwapOracle -vvv
	@echo "✅ SushiSwap scan complete"

# Specific vulnerability tests
test-spot-price:
	@echo "💰 Testing spot price manipulation..."
	forge test --match-test testSpotPriceManipulation -vvv

test-flash-loan:
	@echo "⚡ Testing flash loan attacks..."
	forge test --match-test testFlashLoanAttack -vvv

test-reentrancy:
	@echo "🔄 Testing reentrancy..."
	forge test --match-test testReentrancy -vvv

test-donation:
	@echo "🎁 Testing donation attacks..."
	forge test --match-test testDonationAttack -vvv

# Reporting
report:
	@echo "📊 Generating comprehensive report..."
	@mkdir -p reports
	@echo "# LP Oracle Security Scan Report" > reports/summary.md
	@echo "" >> reports/summary.md
	@echo "## Test Results" >> reports/summary.md
	@forge test --json > reports/foundry-tests.json
	@echo "✅ Report generated in reports/"

report-html:
	@echo "🌐 Generating HTML report..."
	@python3 scripts/generate-html-report.py

# Cleanup
clean:
	@echo "🧹 Cleaning build artifacts..."
	forge clean
	rm -rf out cache coverage reports/*.json

clean-all: clean
	@echo "🧹 Cleaning all generated files..."
	rm -rf lib node_modules corpus

# Development
fmt:
	@echo "✨ Formatting code..."
	forge fmt

lint:
	@echo "🔍 Linting code..."
	forge fmt --check

# Local node
anvil:
	@echo "🔨 Starting Anvil local node..."
	anvil --fork-url $(MAINNET_RPC_URL) --fork-block-number 18500000

# Help
help:
	@echo "LP Oracle Security Scanner - Available Commands:"
	@echo ""
	@echo "Installation:"
	@echo "  make install          - Install Foundry dependencies"
	@echo "  make install-tools    - Install security tools"
	@echo ""
	@echo "Testing:"
	@echo "  make test            - Run all tests"
	@echo "  make test-fuzz       - Run fuzz tests"
	@echo "  make test-coverage   - Generate coverage report"
	@echo "  make fuzz-echidna    - Run Echidna fuzzer"
	@echo ""
	@echo "Analysis:"
	@echo "  make analyze         - Run all static analyzers"
	@echo "  make slither         - Run Slither"
	@echo "  make mythril         - Run Mythril"
	@echo "  make aderyn          - Run Aderyn"
	@echo ""
	@echo "Scanning:"
	@echo "  make scan-all        - Scan all protocols"
	@echo "  make scan-uniswap-v2 - Scan Uniswap V2"
	@echo "  make scan-curve      - Scan Curve"
	@echo ""
	@echo "Specific Tests:"
	@echo "  make test-spot-price - Test spot price manipulation"
	@echo "  make test-flash-loan - Test flash loan attacks"
	@echo "  make test-reentrancy - Test reentrancy"
	@echo ""
	@echo "Utilities:"
	@echo "  make report          - Generate report"
	@echo "  make clean           - Clean build artifacts"
	@echo "  make anvil           - Start local node"