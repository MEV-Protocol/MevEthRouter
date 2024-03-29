// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// ============ Imports ============
import "./interfaces/IWETH.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IGyro.sol";
import "./interfaces/ICurveV2Pool.sol";
import "./interfaces/IMevEth.sol";
import "./interfaces/IRateProvider.sol";
import "./interfaces/IGyroECLPMath.sol";
import "./interfaces/IMevEthRouter.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./libraries/MevEthLibrary.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { WETH } from "solmate/tokens/WETH.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title MevEthRouter
/// @author Manifold Finance
/// @notice mevETH Stake / Redeem optimzed router
/// @dev V1 optimized for 2 routes; Eth (or Weth) => mevEth or mevEth => Eth (or Weth)
///      Aggregated routes are from mevEth deposits / withdraws, Balancer Gyro ECLP, Curve V2 and Uniswap V3 / V2 and Sushiswap
contract MevEthRouter is IUniswapV3SwapCallback, IMevEthRouter {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;

    // Custom errors save gas, encoding to 4 bytes
    error Expired();
    error ZeroAmount();
    error ZeroAddress();
    error ExecuteNotAuthorized();
    error InsufficientOutputAmount();

    /// @dev UniswapV2 / Sushiswap pool 4 byte swap selector
    bytes4 internal constant SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
    /// @dev Wrapped native token address
    WETH internal constant WETH09 = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    /// @dev Wrapped native token address
    IMevEth internal constant MEVETH = IMevEth(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);
    /// @dev Balancer vault
    IVault internal constant BAL = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    /// @dev Gyro ECLP Math lib
    IGyroECLPMath internal constant gyroMath = IGyroECLPMath(0xF89A1713998593A441cdA571780F0900Dbef20f9);
    /// @dev Sushiswap factory address
    address internal constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    /// @dev UniswapV2 factory address
    address internal constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap v2 factory
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4_295_128_739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342;
    /// @dev Sushiswap factory init pair code hash
    bytes32 internal constant SUSHI_FACTORY_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    /// @dev UniswapV2 factory init pair code hash
    bytes32 internal constant UNIV2_FACTORY_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    uint256 internal constant MIN_LIQUIDITY = 1 ether;

    /// @dev Governence for sweeping dust
    address internal gov;
    /// @dev Curve V2 pool address
    address internal curveV2Pool = 0x429cCFCCa8ee06D2B41DAa6ee0e4F0EdBB77dFad;
    /// @dev Gyro pool
    IGyro internal constant gyro = IGyro(0xb3b675a9A3CB0DF8F66Caf08549371BfB76A9867);

    IRateProvider internal constant rateProvider0 = IRateProvider(0xf518f2EbeA5df8Ca2B5E9C7996a2A25e8010014b);

    /// @dev Balancer pool id
    bytes32 internal poolId = 0xb3b675a9a3cb0df8f66caf08549371bfb76a9867000200000000000000000611;

    uint256[3] internal uniV3Caps = [0, 0, 15 ether];

    IGyroECLPMath.Params internal params;
    IGyroECLPMath.DerivedParams internal derived;

    /// @notice struct for pool reserves
    /// @param reserveIn amount of reserves (or virtual reserves) in pool for tokenIn
    /// @param reserveOut amount of reserves (or virtual reserves) in pool for tokenOut
    struct Reserve {
        uint256 reserveIn;
        uint256 reserveOut;
    }

    constructor(address _gov) {
        if (_gov == address(0)) {
            gov = tx.origin;
        } else {
            gov = _gov;
        }

        (params, derived) = gyro.getECLPParams();
    }

    function checkInputs(address receiver, uint256 amountIn, uint256 deadline) internal view {
        // check receiver
        if (receiver == address(0)) revert ZeroAddress();
        // check block.timestamp > deadline (timestamp in seconds)
        ensure(deadline);
        // check amountIn
        if (amountIn == 0) revert ZeroAmount();
    }

    /// @notice Gas efficient stakeEthForMevEth
    /// @dev requires calling getStakeRoute first
    /// @param receiver Address of MevEth receiver
    /// @param amountIn Amount of eth or weth to deposit
    /// @param amountOutMin Min amount of MevEth to receive
    /// @param deadline Timestamp deadline
    /// @param swaps output of getStakeRoute
    /// @return shares Amount of MevEth received
    function stakeEthForMevEth(
        address receiver,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        Swap calldata swaps
    )
        external
        payable
        returns (uint256 shares)
    {
        // check inputs
        checkInputs(receiver, amountIn, deadline);
        // check eth or weth deposit
        if (msg.value != amountIn) {
            // either weth or wrong amount
            // transfer weth amountIn from sender, will revert if insufficient allowance
            WETH09.safeTransferFrom(msg.sender, address(this), amountIn);
        } else {
            WETH09.deposit{ value: amountIn }();
        }

        // UniV2 / Sushi require amounts transfered directly to pool
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps.pools[i].amountIn)) {
                WETH09.safeTransfer(swaps.pools[i].pair, swaps.pools[i].amountIn);
            }
        }

        // execute swaps, retreive actual amounts
        uint256[] memory amounts = _swap(true, receiver, deadline, swaps);
        // check output is sufficient
        if (amountOutMin > amounts[1]) revert InsufficientOutputAmount();
        // assign returned shares
        shares = amounts[1];
        //  refund V3 dust if any
        if (amounts[0] < amountIn && (amountIn - amounts[0]) > 50_000 * block.basefee) {
            WETH09.safeTransfer(msg.sender, amountIn - amounts[0]);
        }
    }

    /// @notice Gas efficient redeemMevEthForEth
    /// @dev requires calling getRedeemRoute first
    /// @param receiver Address of Eth receiver
    /// @param shares Amount of meveth to redeem
    /// @param amountOutMin Min amount of eth to receive
    /// @param deadline Timestamp deadline
    /// @param swaps output of getRedeemRoute
    /// @return assets Eth received
    function redeemMevEthForEth(
        bool useQueue,
        address receiver,
        uint256 shares,
        uint256 amountOutMin,
        uint256 deadline,
        Swap calldata swaps
    )
        external
        returns (uint256 assets)
    {
        // check inputs
        checkInputs(receiver, shares, deadline);
        // check eth or weth deposit
        ERC20(address(MEVETH)).safeTransferFrom(msg.sender, address(this), shares);

        // UniV2 / Sushi require amounts transfered directly to pool
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps.pools[i].amountIn)) {
                ERC20(address(MEVETH)).safeTransfer(swaps.pools[i].pair, swaps.pools[i].amountIn);
            }
        }

        // execute swaps, retreive actual amounts
        uint256[] memory amounts = _swap(useQueue, receiver, deadline, swaps);
        // check output is sufficient
        if (amountOutMin > amounts[1]) revert InsufficientOutputAmount();
        // assign returned shares
        assets = amounts[1];
        //  refund V3 dust if any
        if (amounts[0] < shares && (shares - amounts[0]) > 50_000 * block.basefee) {
            ERC20(address(MEVETH)).safeTransfer(msg.sender, shares - amounts[0]);
        }
    }

    /// @dev calculate pool addresses for token0/1 & factory/fee
    function _getPools() internal view returns (Pool[8] memory pools) {
        pools[0].pair = MevEthLibrary._asmPairFor(SUSHI_FACTORY, address(MEVETH), address(WETH09), SUSHI_FACTORY_HASH); // sushi
        pools[1].pair = MevEthLibrary._asmPairFor(UNIV2_FACTORY, address(MEVETH), address(WETH09), UNIV2_FACTORY_HASH); // univ2
        pools[2].pair = MevEthLibrary.uniswapV3PoolAddress(address(MEVETH), address(WETH09), 3000); // univ3 0.3 %
        pools[3].pair = MevEthLibrary.uniswapV3PoolAddress(address(MEVETH), address(WETH09), 500); // univ3 0.05 %
        pools[4].pair = MevEthLibrary.uniswapV3PoolAddress(address(MEVETH), address(WETH09), 10_000); // univ3 1 %
        pools[5].pair = MevEthLibrary._getBalancerPoolAddress(poolId);
        pools[6].pair = curveV2Pool;
        pools[7].pair = address(MEVETH);
    }

    function balancerInvariant(uint256[] memory balances) internal view returns (IGyroECLPMath.Vector2 memory inv) {
        // for some reason GyroECLPMath lib has a different selector
        // bytes memory data = abi.encodeWithSelector(0x78ace857, balances, params, derived);
        (, bytes memory returnData) = address(gyroMath).staticcall(abi.encodeWithSelector(0x78ace857, balances, params, derived));
        (int256 invariant, int256 err) = abi.decode(returnData, (int256, int256));
        // (int256 invariant, int256 err) = gyroMath.calculateInvariantWithError(balances, params, derived);
        inv = IGyroECLPMath.Vector2(invariant + 2 * err, invariant);
    }

    /// @notice Fetches swap data for each pair and amounts given an input amount
    /// @param amountIn Amount in for first token in path
    /// @param amountOutMin Min amount out
    /// @return swaps struct for split order details
    function getStakeRoute(uint256 amountIn, uint256 amountOutMin) internal view returns (Swap memory swaps) {
        swaps.isDeposit = true;
        swaps.pools = _getPools();
        swaps.tokenIn = address(WETH09);
        swaps.tokenOut = address(MEVETH);
        uint256[8] memory amountsIn;
        uint256[8] memory amountsOut;
        {
            Reserve[8] memory reserves = _getReserves(true, swaps.pools);
            // find optimal route
            (amountsIn, amountsOut) = _optimalRouteOut(false, true, amountIn, amountOutMin, reserves);
        }
        for (uint256 j; j < 8; j = _inc(j)) {
            swaps.pools[j].amountIn = amountsIn[j];
            swaps.pools[j].amountOut = amountsOut[j];
        }
    }

    /// @notice Fetches swap data for each pair and amounts given an input amount
    /// @param useQueue Use redeem queue
    /// @param amountIn Amount in for first token in path
    /// @param amountOutMin Min amount out
    /// @return swaps struct for split order details
    function getRedeemRoute(bool useQueue, uint256 amountIn, uint256 amountOutMin) internal view returns (Swap memory swaps) {
        swaps.pools = _getPools();
        swaps.tokenIn = address(MEVETH);
        swaps.tokenOut = address(WETH09);
        uint256[8] memory amountsIn;
        uint256[8] memory amountsOut;
        {
            Reserve[8] memory reserves = _getReserves(false, swaps.pools);

            // find optimal route
            (amountsIn, amountsOut) = _optimalRouteOut(useQueue, false, amountIn, amountOutMin, reserves);
        }
        for (uint256 j; j < 8; j = _inc(j)) {
            swaps.pools[j].amountIn = amountsIn[j];
            swaps.pools[j].amountOut = amountsOut[j];
        }
    }

    /// @notice Amount out expected from stake
    /// @param amountIn Amount in for first token in path
    /// @return amountOut Expected amountOut
    /// @return swaps struct for split order details
    function amountOutStake(uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps) {
        swaps = getStakeRoute(amountIn, 1);
        for (uint256 j; j < 8; j = _inc(j)) {
            amountOut += swaps.pools[j].amountOut;
        }
    }

    /// @notice Amount out expected from redeem
    /// @param useQueue Use redeem queue
    /// @param amountIn Amount in for first token in path
    /// @return amountOut Expected amountOut
    /// @return swaps struct for split order details
    function amountOutRedeem(bool useQueue, uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps) {
        swaps = getRedeemRoute(useQueue, amountIn, 1);
        for (uint256 j; j < 8; j = _inc(j)) {
            amountOut += swaps.pools[j].amountOut;
        }
    }

    /// @dev populates and returns Reserve struct array for each pool address
    /// @param isDeposit true if deposit eth, false if redeem
    /// @param pools 5 element array of Pool structs populated with pool addresses
    function _getReserves(bool isDeposit, Pool[8] memory pools) internal view returns (Reserve[8] memory reserves) {
        // 2 V2 pools
        for (uint256 i; i < 2; i = _inc(i)) {
            if (!MevEthLibrary.isContract(pools[i].pair)) continue;
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pools[i].pair).getReserves();
            (reserves[i].reserveIn, reserves[i].reserveOut) = isDeposit ? (reserve1, reserve0) : (reserve0, reserve1);
        }
        // 3 V3 pools
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (!MevEthLibrary.isContract(pools[i].pair)) continue;
            (uint160 sqrtPriceX96, int24 tick) = IUniswapV3Pool(pools[i].pair).slot0();
            if (tick == 0) continue;
            uint256 liquidity = uint256(IUniswapV3Pool(pools[i].pair).liquidity());
            if (_isNonZero(liquidity) && _isNonZero(sqrtPriceX96)) {
                unchecked {
                    uint256 reserve0 = (liquidity * uint256(2 ** 96)) / uint256(sqrtPriceX96);
                    uint256 reserve1 = (liquidity * uint256(sqrtPriceX96)) / uint256(2 ** 96);
                    (reserves[i].reserveIn, reserves[i].reserveOut) = isDeposit ? (reserve1, reserve0) : (reserve0, reserve1);
                }
            }
        }
        // Balancer (i=5)
        {
            uint256[] memory balances = _getAllBalances();
            (reserves[5].reserveIn, reserves[5].reserveOut) = isDeposit ? (balances[1], balances[0]) : (balances[0], balances[1]);
        }
        // Curve CryptoV2 (i=6)
        // Note: Curve token order is opposite from balancer / uni / sushi
        {
            uint256 reserve0 = ICurveV2Pool(pools[6].pair).balances(0);
            uint256 reserve1 = ICurveV2Pool(pools[6].pair).balances(1);
            (reserves[6].reserveIn, reserves[6].reserveOut) = isDeposit ? (reserve0, reserve1) : (reserve1, reserve0);
        }
        // MevEth (i=7)
        // Note: MevEth token order is opposite from balancer / uni / sushi
        {
            (uint256 reserve0, uint256 reserve1) = MEVETH.fraction();
            (reserves[7].reserveIn, reserves[7].reserveOut) = isDeposit ? (reserve0, reserve1) : (reserve1, reserve0);
        }
    }

    /// @dev sorts possible swaps by best price, then assigns optimal split
    function _optimalRouteOut(
        bool useQueue,
        bool isDeposit,
        uint256 amountIn,
        uint256 amountOutMin,
        Reserve[8] memory reserves
    )
        internal
        view
        returns (uint256[8] memory amountsIn, uint256[8] memory amountsOut)
    {
        // calculate best rate for a single swap (i.e. no splitting)
        uint256[8] memory amountsOutSingleSwap;
        // get ref rate for splits
        uint256[8] memory amountsOutSingleEth;

        // calc balancer invariant
        uint256[] memory balances = new uint256[](2);
        balances[0] = isDeposit ? reserves[5].reserveOut : reserves[5].reserveIn;
        balances[1] = isDeposit ? reserves[5].reserveIn : reserves[5].reserveOut;
        IGyroECLPMath.Vector2 memory inv = balancerInvariant(balances);

        // first 2 pools have fee of 0.3%
        for (uint256 i; i < 2; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOutMin) {
                amountsOutSingleSwap[i] = amountOutCall(isDeposit, i, amountIn, reserves[i].reserveIn, reserves[i].reserveOut, inv);
            }
            if (reserves[i].reserveOut > MIN_LIQUIDITY && reserves[i].reserveIn > MIN_LIQUIDITY && amountIn > MIN_LIQUIDITY) {
                amountsOutSingleEth[i] = amountOutCall(isDeposit, i, 1 ether, reserves[i].reserveIn, reserves[i].reserveOut, inv);
            }
        }
        // next 3 pools have variable rates
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOutMin && reserves[i].reserveIn > amountIn) {
                amountsOutSingleSwap[i] = amountOutCall(isDeposit, i, amountIn, reserves[i].reserveIn, reserves[i].reserveOut, inv);
            }
            if (reserves[i].reserveOut > MIN_LIQUIDITY && reserves[i].reserveIn > MIN_LIQUIDITY && amountIn > MIN_LIQUIDITY) {
                amountsOutSingleEth[i] = amountOutCall(isDeposit, i, 1 ether, reserves[i].reserveIn, reserves[i].reserveOut, inv);
            }
        }
        // Balancer pool (todo: embed amount out calc)
        if (reserves[5].reserveOut > amountOutMin) {
            amountsOutSingleSwap[5] = amountOutCall(isDeposit, 5, amountIn, reserves[5].reserveIn, reserves[5].reserveOut, inv);
        }
        if (reserves[5].reserveOut > MIN_LIQUIDITY && amountIn > MIN_LIQUIDITY) {
            amountsOutSingleEth[5] = amountOutCall(isDeposit, 5, 1 ether, reserves[5].reserveIn, reserves[5].reserveOut, inv);
        }

        // Curve pool (todo: embed amount out calc)
        if (reserves[6].reserveOut > amountOutMin) {
            amountsOutSingleSwap[6] = amountOutCall(isDeposit, 6, amountIn, reserves[6].reserveIn, reserves[6].reserveOut, inv);
        }
        if (reserves[6].reserveOut > MIN_LIQUIDITY && amountIn > MIN_LIQUIDITY) {
            amountsOutSingleEth[6] = amountOutCall(isDeposit, 6, 1 ether, reserves[6].reserveIn, reserves[6].reserveOut, inv);
        }
        // MevEth
        if (isDeposit) {
            amountsOutSingleSwap[7] = reserves[7].reserveOut * amountIn / reserves[7].reserveIn;
            if (amountIn > MIN_LIQUIDITY) {
                amountsOutSingleEth[7] = reserves[7].reserveOut * 1 ether / (reserves[7].reserveIn);
            }
        } else {
            if (useQueue) {
                amountsOutSingleSwap[7] = reserves[7].reserveOut * amountIn * 9999 / (10_000 * reserves[7].reserveIn);
                if (amountIn > MIN_LIQUIDITY) {
                    amountsOutSingleEth[7] = reserves[7].reserveOut * 1 ether * 9999 / (10_000 * reserves[7].reserveIn);
                }
            }
        }

        (amountsIn, amountsOut) = _splitSwapOut(isDeposit, amountIn, inv, amountsOutSingleSwap, amountsOutSingleEth, reserves);
    }

    function _scalingFactor(bool token0) internal view returns (uint256 scalingFactor) {
        scalingFactor = 1 ether;
        if (token0) {
            scalingFactor = rateProvider0.getRate();
        }
    }

    /**
     * @dev Reads the balance of a token from the balancer vault and returns the scaled amount. Smaller storage access
     * compared to getVault().getPoolTokens().
     * Copied from the 3CLP *except* that for the 2CLP, the scalingFactor is interpreted as a regular integer, not a
     * FixedPoint number. This is an inconsistency between the base contracts.
     */
    function _getScaledTokenBalance(address token, uint256 scalingFactor) internal view returns (uint256 balance) {
        // Signature of getPoolTokenInfo(): (pool id, token) -> (cash, managed, lastChangeBlock, assetManager)
        // and total amount = cash + managed. See balancer repo, PoolTokens.sol and BalanceAllocation.sol
        (uint256 cash, uint256 managed,,) = BAL.getPoolTokenInfo(poolId, token);
        balance = cash + managed; // can't overflow, see BalanceAllocation.sol::total() in the Balancer repo.
        balance = balance * scalingFactor / 1 ether;
    }

    /**
     * @dev Get all balances in the pool, scaled by the appropriate scaling factors, in a relatively gas-efficient way.
     * Essentially copied from the 3CLP.
     */
    function _getAllBalances() internal view returns (uint256[] memory balances) {
        balances = new uint256[](2);
        balances[0] = _getScaledTokenBalance(address(MEVETH), _scalingFactor(true));
        balances[1] = _getScaledTokenBalance(address(WETH09), _scalingFactor(false));
        return balances;
    }

    function balancerAmountOut(
        bool isDeposit,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        IGyroECLPMath.Vector2 memory inv
    )
        internal
        view
        returns (uint256 amountOut)
    {

        uint256[] memory balances = new uint256[](2);
        balances[0] = isDeposit ? reserveOut : reserveIn;
        balances[1] = isDeposit ? reserveIn : reserveOut;

        amountIn = (amountIn - amountIn * MevEthLibrary.getFee(5) / 1_000_000) * _scalingFactor(!isDeposit) / 1 ether;

        // same selector workaround here
        (, bytes memory returnData) = address(gyroMath).staticcall(abi.encodeWithSelector(0x61ff4236, balances, amountIn, !isDeposit, params, derived, inv));

        amountOut = abi.decode(returnData, (uint256)) * 1 ether / _scalingFactor(isDeposit);
    }

    function amountOutCall(
        bool isDeposit,
        uint256 i,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        IGyroECLPMath.Vector2 memory inv
    )
        internal
        view
        returns (uint256 amountOut)
    {
        if (i < 2) {
            if (reserveOut > MIN_LIQUIDITY && amountIn < reserveOut) {
                amountOut = MevEthLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
            }
        } else if (i < 5) {
            if (reserveOut > MIN_LIQUIDITY && reserveIn > MIN_LIQUIDITY && amountIn < reserveOut / 4 && amountIn < uniV3Caps[i - 2]) {
                amountOut = MevEthLibrary.getAmountOutFee(amountIn, reserveIn, reserveOut, MevEthLibrary.getFee(i));
            }
        }
        // Balancer pool
        if (i == 5) {
            if (reserveOut > MIN_LIQUIDITY && amountIn < reserveOut / 2) {
                amountOut = balancerAmountOut(isDeposit, amountIn, reserveIn, reserveOut, inv);
            }
        }

        // Curve pool (todo: embed amount out calc)
        if (i == 6) {
            if (reserveOut > MIN_LIQUIDITY && amountIn < reserveOut / 2) {
                amountOut = isDeposit ? ICurveV2Pool(curveV2Pool).get_dy(0, 1, amountIn) : ICurveV2Pool(curveV2Pool).get_dy(1, 0, amountIn);
            }
        }

        // MevEth
        if (i == 7) {
            amountOut = isDeposit ? reserveOut * amountIn / reserveIn : reserveOut * amountIn * 9999 / (10_000 * reserveIn);
        }
    }

    /// @notice assigns optimal route for maximum amount out, given pool reserves
    function _splitSwapOut(
        bool isDeposit,
        uint256 amountIn,
        IGyroECLPMath.Vector2 memory inv,
        uint256[8] memory amountsOutSingleSwap,
        uint256[8] memory amountsOutSingleEth,
        Reserve[8] memory reserves
    )
        internal
        view
        returns (uint256[8] memory amountsIn, uint256[8] memory amountsOut)
    {
        uint256[8] memory index = MevEthLibrary._sortArray(amountsOutSingleSwap); // sorts in ascending order (i.e. best price is last)
        // First check best single swap price and return if no split is needed
        if (_isNonZero(amountsOutSingleSwap[index[7]]) && amountIn <= MIN_LIQUIDITY) {
            amountsIn[index[7]] = amountIn; // use best single swap price
            amountsOut[index[7]] = amountsOutSingleSwap[index[7]];
            return (amountsIn, amountsOut);
        }

        uint256[8] memory index2 = MevEthLibrary._sortArray(amountsOutSingleEth); // sorts in ascending order (i.e. best price is last)
        if (_isNonZero(amountsOutSingleEth[index2[7]])) {
            uint256 cumulativeAmount;
            // calculate amount to sync prices cascading through each pool with best prices first, while cumulative amount < amountIn
            for (uint256 i = 7; _isNonZero(i); i = _dec(i)) {
                if (index2[i] == 7 || _isZero(amountsOutSingleEth[index2[_dec(i)]])) {
                    // meveth rate is fixed so no more iterations required
                    // other case is there are no more viable pools to swap
                    amountsIn[index2[i]] = amountIn - cumulativeAmount;
                    amountsOut[index2[i]] =
                        amountOutCall(isDeposit, index2[i], amountsIn[index2[i]], reserves[index2[i]].reserveIn, reserves[index2[i]].reserveOut, inv);
                    // return (amountsIn, amountsOut);
                } else {
                    (amountsIn[index2[i]], amountsOut[index2[i]]) = amountToSync(
                        isDeposit,
                        amountIn,
                        cumulativeAmount,
                        index2[i],
                        amountsOutSingleEth[index2[_dec(i)]],
                        reserves[index2[i]].reserveIn,
                        reserves[index2[i]].reserveOut,
                        inv
                    );

                }

                cumulativeAmount = cumulativeAmount + amountsIn[index2[i]];
                if (cumulativeAmount == amountIn) break;
                if (_isZero(amountsOutSingleEth[index2[_dec(i)]])) break;
            }
        }
    }

    function amountToSync(
        bool isDeposit,
        uint256 amountIn,
        uint256 cumulativeAmount,
        uint256 index,
        uint256 amountsOutSingleEthTarget,
        uint256 reserveIn,
        uint256 reserveOut,
        IGyroECLPMath.Vector2 memory inv
    )
        internal
        view
        returns (uint256 amountInToSync, uint256 amountOut)
    {
        uint256 amount;
        uint256 chunk = amountIn / 10;
        // uint256 precision = 0.1 ether;
        if (chunk < 0.1 ether) {
            chunk = 0.1 ether;
        }

        for (uint256 i; i < 10; i = _inc(i)) {
            amount = amount + chunk;

            bool endLoop;
            if (index > 1 && index < 5 && amount > uniV3Caps[index - 2]) {
                amount = uniV3Caps[index - 2];
                endLoop = true;
                // hard cap univ3 amounts as they become more unpredictable
            }
            if (amount + 0.1 ether > amountIn - cumulativeAmount) {
                amount = amountIn - cumulativeAmount;
                endLoop = true;
            }

            {
                uint256 amountOutTmp = amountOutCall(isDeposit, index, amount, reserveIn, reserveOut, inv);
                if (amountOutTmp * 1 ether / amountsOutSingleEthTarget < amount) break;
                amountOut = amountOutTmp;
            }

            amountInToSync = amount;

            if (endLoop) return (amountInToSync, amountOut);
        }
        // refine
        if (chunk > 0.1 ether) {
            amount = amountInToSync;

            chunk = chunk / 10;
            for (uint256 i; i < 10; i = _inc(i)) {
                amount = amount + chunk;
                bool endLoop;
                if (amount > amountIn - cumulativeAmount) {
                    amount = amountIn - cumulativeAmount;
                    endLoop = true;
                }

                {
                    uint256 amountOutTmp = amountOutCall(isDeposit, index, amount, reserveIn, reserveOut, inv);
                    if (amountOutTmp * 1 ether / amountsOutSingleEthTarget < amount) break;
                    amountOut = amountOutTmp;
                }

                amountInToSync = amount;

                if (endLoop) return (amountInToSync, amountOut);
            }
        }

        if (amountInToSync == 0) {
            amountOut = 0;
        }
    }

    /// @dev Callback for Uniswap V3 pool.
    /// @param amount0Delta amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)
    /// @param amount1Delta amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)
    /// @param data tokenIn,tokenOut and fee packed bytes
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        address pool;
        address tokenIn;
        {
            uint24 fee;
            address tokenOut;
            (tokenIn, tokenOut, fee) = _decode(data); // custom decode packed (address, address, uint24)
            (address token0, address token1) = MevEthLibrary.sortTokens(tokenIn, tokenOut);
            pool = MevEthLibrary.uniswapV3PoolAddress(token0, token1, fee); // safest way to check pool address is valid and pool was the msg sender
        }
        if (msg.sender != pool) revert ExecuteNotAuthorized();
        // uni v3 optimistically sends tokenOut funds, then calls this function for the tokenIn amount
        if (amount0Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount1Delta));
    }

    /// @notice Ensures deadline is not passed, otherwise revert.
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    /// @dev single swap for uni v2 pair. Requires the initial amount to have already been sent to the first pair.
    /// @param isReverse true if token0 == tokenOut
    /// @param to swap recipient
    /// @param pair pair address
    /// @param amountOut expected amount out
    function _swapSingle(bool isReverse, address to, address pair, uint256 amountOut) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    /// @dev single swap for uni v3 pool
    /// @param isReverse true if token0 == tokenOut
    /// @param fee fee of pool as a ratio of 1000000
    /// @param to swap recipient
    /// @param tokenIn token in address
    /// @param tokenOut token out address
    /// @param pair pair address
    /// @param amountIn amount of tokenIn
    function _swapUniV3(
        bool isReverse,
        uint24 fee,
        address to,
        address tokenIn,
        address tokenOut,
        address pair,
        uint256 amountIn
    )
        internal
        virtual
        returns (uint256 amountInActual, uint256 amountOut)
    {

        try IUniswapV3Pool(pair).swap(
            to, !isReverse, int256(amountIn), isReverse ? MAX_SQRT_RATIO - 1 : MIN_SQRT_RATIO + 1, abi.encodePacked(tokenIn, tokenOut, fee)
        ) returns (int256 amount0, int256 amount1) {
            amountOut = isReverse ? uint256(-(amount0)) : uint256(-(amount1));
            amountInActual = isReverse ? uint256(amount1) : uint256(amount0);
        } catch {
            amountOut = 0;
        }
    }


    /// @dev Internal core swap. Requires the initial amount to have already been sent to the first pair (for v2 pairs).
    /// @param useQueue Use queue or not for withdrawals
    /// @param to Address of receiver
    /// @param deadline timstamp of expiry
    /// @param swaps Array of user swap data
    function _swap(bool useQueue, address to, uint256 deadline, Swap memory swaps) internal virtual returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        uint256 amountIn;
        for (uint256 i; i < 8; i = _inc(i)) {
            amounts[0] = amounts[0] + swaps.pools[i].amountIn; // gather amounts in from each route
        }

        // V2 swaps
        for (uint256 j; j < 2; j = _inc(j)) {
            amountIn = swaps.pools[j].amountIn;
            if (_isNonZero(amountIn)) {
                _swapSingle(swaps.isDeposit, to, swaps.pools[j].pair, swaps.pools[j].amountOut); // single v2 swap
                amounts[1] = amounts[1] + swaps.pools[j].amountOut;
            }
        }
        // V3 swaps
        for (uint256 j = 2; j < 5; j = _inc(j)) {
            amountIn = swaps.pools[j].amountIn;
            if (_isNonZero(amountIn)) {
                (, uint256 amountOut) =
                    _swapUniV3(swaps.isDeposit, uint24(MevEthLibrary.getFee(j)), to, swaps.tokenIn, swaps.tokenOut, swaps.pools[j].pair, amountIn); // single v3
                    // swap
                amounts[1] = amounts[1] + amountOut;
                if (amountOut == 0) {
                    // uniV3 swap failed if here
                    if (useQueue) {
                        // add to mevEth order
                        swaps.pools[7].amountIn = swaps.pools[7].amountIn + amountIn;
                    } else {
                        // try adding to balancer for buy or curve for sell
                        if (swaps.tokenIn == address(WETH09)) {
                            swaps.pools[5].amountIn = swaps.pools[5].amountIn + amountIn;
                        } else {
                            swaps.pools[6].amountIn = swaps.pools[6].amountIn + amountIn;
                        }
                    }
                }
            }
        }
        // Balancer swap
        amountIn = swaps.pools[5].amountIn;
        if (_isNonZero(amountIn)) {
            IVault.SingleSwap memory singleSwap = IVault.SingleSwap(poolId, IVault.SwapKind.GIVEN_IN, swaps.tokenIn, swaps.tokenOut, amountIn, new bytes(0));
            IVault.FundManagement memory fund = IVault.FundManagement(address(this), false, payable(to), false);
            if (swaps.tokenIn == address(WETH09)) {
                WETH09.approve(address(BAL), amountIn);
            } else {
                ERC20(address(MEVETH)).approve(address(BAL), amountIn);
            }
            amounts[1] = amounts[1] + BAL.swap(singleSwap, fund, 1, deadline);
        }
        // Curve swap
        amountIn = swaps.pools[6].amountIn;
        if (_isNonZero(amountIn)) {
            if (swaps.tokenIn == address(WETH09)) {
                // Contrary to the other pools, token order is WETH / MEVETH
                WETH09.approve(curveV2Pool, amountIn);
                amounts[1] = amounts[1] + ICurveV2Pool(curveV2Pool).exchange(0, 1, amountIn, 1, false, to);
            } else {
                ERC20(address(MEVETH)).approve(curveV2Pool, amountIn);
                amounts[1] = amounts[1] + ICurveV2Pool(curveV2Pool).exchange(1, 0, amountIn, 1, false, to);
            }
        }
        // MevEth deposit / redeem
        amountIn = swaps.pools[7].amountIn;
        if (_isNonZero(swaps.pools[7].amountIn)) {
            if (swaps.tokenIn == address(WETH09)) {
                WETH09.approve(address(MEVETH), amountIn);
                amounts[1] = amounts[1] + MEVETH.deposit(amountIn, to);
            } else {
                ERC20(address(MEVETH)).approve(address(MEVETH), amountIn);
                if (useQueue) {
                    MEVETH.withdrawQueue(MEVETH.previewRedeem(amountIn) - 1, to, address(this));
                    amounts[1] = amounts[1] + MEVETH.previewRedeem(amountIn);
                }
            }
        }
    }

    /// @custom:assembly Efficient single swap call
    /// @notice Internal call to perform single swap
    /// @param pair Address of pair to swap in
    /// @param amount0Out AmountOut for token0 of pair
    /// @param amount1Out AmountOut for token1 of pair
    /// @param to Address of receiver
    function _asmSwap(address pair, uint256 amount0Out, uint256 amount1Out, address to) internal {
        bytes4 selector = SWAP_SELECTOR;
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, selector) // append 4 byte selector
            mstore(add(ptr, 0x04), amount0Out) // append amount0Out
            mstore(add(ptr, 0x24), amount1Out) // append amount1Out
            mstore(add(ptr, 0x44), to) // append to
            mstore(add(ptr, 0x64), 0x80) // append location of byte list
            mstore(add(ptr, 0x84), 0) // append 0 bytes data
            let success :=
                call(
                    gas(), // gas remaining
                    pair, // destination address
                    0, // 0 value
                    ptr, // input buffer
                    0xA4, // input length
                    0, // output buffer
                    0 // output length
                )

            if iszero(success) {
                // 0 size error is the cheapest, but mstore an error enum if you wish
                revert(0x0, 0x0)
            }
        }
    }

    /// @custom:assembly De-compresses 2 addresses and 1 uint24 from byte stream (len = 43)
    /// @notice De-compresses 2 addresses and 1 uint24 from byte stream (len = 43)
    /// @param data Compressed byte stream
    /// @return a Address of first param
    /// @return b Address of second param
    /// @return fee (0.3% => 3000 ...)
    function _decode(bytes memory data) internal pure returns (address a, address b, uint24 fee) {
        // MLOAD Only, so it's safe
        assembly ("memory-safe") {
            // first 32 bytes are reserved for bytes length
            a := mload(add(data, 20)) // load last 20 bytes of 32 + 20 (52-32=20)
            b := mload(add(data, 40)) // load last 20 bytes of 32 + 40 (72-32=40)
            fee := mload(add(data, 43)) // load last 3 bytes of 32 + 43 (75-32=43)
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256 result) {
        // Stack only safety
        assembly ("memory-safe") {
            result := add(i, 1)
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256 result) {
        // Stack Only Safety
        assembly ("memory-safe") {
            result := sub(i, 1)
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable { }

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable { }

    function changeGov(address newGov) external {
        if (msg.sender != gov) revert ExecuteNotAuthorized();
        if (newGov == address(0)) revert ZeroAddress();
        gov = newGov;
    }

    function changePoolId(bytes32 newPoolId) external {
        if (msg.sender != gov) revert ExecuteNotAuthorized();
        poolId = newPoolId;
    }

    function changeCurvePool(address newCurvePool) external {
        if (msg.sender != gov) revert ExecuteNotAuthorized();
        if (newCurvePool == address(0)) revert ZeroAddress();
        curveV2Pool = newCurvePool;
    }

    function changeUniV3Caps(uint256[3] calldata caps) external {
        if (msg.sender != gov) revert ExecuteNotAuthorized();
        uniV3Caps = caps;
    }

    /// @notice Sweep dust tokens and eth to recipient
    /// @param tokens Array of token addresses
    /// @param recipient Address of recipient
    function sweep(address[] calldata tokens, address recipient) external {
        if (msg.sender != gov) revert ExecuteNotAuthorized();
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            ERC20(token).safeTransfer(recipient, ERC20(token).balanceOf(address(this)));
        }
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }
}
