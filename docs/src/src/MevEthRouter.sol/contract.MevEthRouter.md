# MevEthRouter
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/MevEthRouter.sol)

**Inherits:**
[IUniswapV3SwapCallback](/src/interfaces/IUniswapV3SwapCallback.sol/interface.IUniswapV3SwapCallback.md), [IMevEthRouter](/src/interfaces/IMevEthRouter.sol/interface.IMevEthRouter.md)

**Author:**
Manifold Finance

============ Imports ============

mevETH Stake / Redeem optimzed router

*V1 optimized for 2 routes; Eth (or Weth) => mevEth or mevEth => Eth (or Weth)
Aggregated routes are from mevEth deposits / withdraws, Balancer Gyro ECLP, Curve V2 and Uniswap V3 / V2 and Sushiswap*


## State Variables
### SWAP_SELECTOR
*UniswapV2 / Sushiswap pool 4 byte swap selector*


```solidity
bytes4 internal constant SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
```


### WETH09
*Wrapped native token address*


```solidity
WETH internal constant WETH09 = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
```


### MEVETH
*Wrapped native token address*


```solidity
IMevEth internal constant MEVETH = IMevEth(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);
```


### BAL
*Balancer vault*


```solidity
IVault internal constant BAL = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
```


### gyroMath
*Gyro ECLP Math lib*


```solidity
IGyroECLPMath internal constant gyroMath = IGyroECLPMath(0xF89A1713998593A441cdA571780F0900Dbef20f9);
```


### SUSHI_FACTORY
*Sushiswap factory address*


```solidity
address internal constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
```


### UNIV2_FACTORY
*UniswapV2 factory address*


```solidity
address internal constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
```


### MIN_SQRT_RATIO
*The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)*


```solidity
uint160 internal constant MIN_SQRT_RATIO = 4_295_128_739;
```


### MAX_SQRT_RATIO
*The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)*


```solidity
uint160 internal constant MAX_SQRT_RATIO = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342;
```


### SUSHI_FACTORY_HASH
*Sushiswap factory init pair code hash*


```solidity
bytes32 internal constant SUSHI_FACTORY_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
```


### UNIV2_FACTORY_HASH
*UniswapV2 factory init pair code hash*


```solidity
bytes32 internal constant UNIV2_FACTORY_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
```


### MIN_LIQUIDITY

```solidity
uint256 internal constant MIN_LIQUIDITY = 1 ether;
```


### gov
*Governence for sweeping dust*


```solidity
address internal gov;
```


### curveV2Pool
*Curve V2 pool address*


```solidity
address internal curveV2Pool = 0x429cCFCCa8ee06D2B41DAa6ee0e4F0EdBB77dFad;
```


### gyro
*Gyro pool*


```solidity
IGyro internal constant gyro = IGyro(0xb3b675a9A3CB0DF8F66Caf08549371BfB76A9867);
```


### rateProvider0

```solidity
IRateProvider internal constant rateProvider0 = IRateProvider(0xf518f2EbeA5df8Ca2B5E9C7996a2A25e8010014b);
```


### poolId
*Balancer pool id*


```solidity
bytes32 internal poolId = 0xb3b675a9a3cb0df8f66caf08549371bfb76a9867000200000000000000000611;
```


### uniV3Caps

```solidity
uint256[3] internal uniV3Caps = [0, 0, 15 ether];
```


### params

```solidity
IGyroECLPMath.Params internal params;
```


### derived

```solidity
IGyroECLPMath.DerivedParams internal derived;
```


## Functions
### constructor


```solidity
constructor(address _gov);
```

### checkInputs


```solidity
function checkInputs(address receiver, uint256 amountIn, uint256 deadline) internal view;
```

### stakeEthForMevEth

Gas efficient stakeEthForMevEth

*requires calling getStakeRoute first*


```solidity
function stakeEthForMevEth(
    address receiver,
    uint256 amountIn,
    uint256 amountOutMin,
    uint256 deadline,
    Swap calldata swaps
)
    external
    payable
    returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|Address of MevEth receiver|
|`amountIn`|`uint256`|Amount of eth or weth to deposit|
|`amountOutMin`|`uint256`|Min amount of MevEth to receive|
|`deadline`|`uint256`|Timestamp deadline|
|`swaps`|`Swap`|output of getStakeRoute|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|Amount of MevEth received|


### redeemMevEthForEth

Gas efficient redeemMevEthForEth

*requires calling getRedeemRoute first*


```solidity
function redeemMevEthForEth(
    bool useQueue,
    address receiver,
    uint256 shares,
    uint256 amountOutMin,
    uint256 deadline,
    Swap calldata swaps
)
    external
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`useQueue`|`bool`||
|`receiver`|`address`|Address of Eth receiver|
|`shares`|`uint256`|Amount of meveth to redeem|
|`amountOutMin`|`uint256`|Min amount of eth to receive|
|`deadline`|`uint256`|Timestamp deadline|
|`swaps`|`Swap`|output of getRedeemRoute|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|Eth received|


### _getPools

*calculate pool addresses for token0/1 & factory/fee*


```solidity
function _getPools() internal view returns (Pool[8] memory pools);
```

### balancerInvariant


```solidity
function balancerInvariant(uint256[] memory balances) internal view returns (IGyroECLPMath.Vector2 memory inv);
```

### getStakeRoute

Fetches swap data for each pair and amounts given an input amount


```solidity
function getStakeRoute(uint256 amountIn, uint256 amountOutMin) internal view returns (Swap memory swaps);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`|Amount in for first token in path|
|`amountOutMin`|`uint256`|Min amount out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`swaps`|`Swap`|struct for split order details|


### getRedeemRoute

Fetches swap data for each pair and amounts given an input amount


```solidity
function getRedeemRoute(bool useQueue, uint256 amountIn, uint256 amountOutMin) internal view returns (Swap memory swaps);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`useQueue`|`bool`|Use redeem queue|
|`amountIn`|`uint256`|Amount in for first token in path|
|`amountOutMin`|`uint256`|Min amount out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`swaps`|`Swap`|struct for split order details|


### amountOutStake

Amount out expected from stake


```solidity
function amountOutStake(uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`|Amount in for first token in path|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Expected amountOut|
|`swaps`|`Swap`|struct for split order details|


### amountOutRedeem

Amount out expected from redeem


```solidity
function amountOutRedeem(bool useQueue, uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`useQueue`|`bool`|Use redeem queue|
|`amountIn`|`uint256`|Amount in for first token in path|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Expected amountOut|
|`swaps`|`Swap`|struct for split order details|


### _getReserves

*populates and returns Reserve struct array for each pool address*


```solidity
function _getReserves(bool isDeposit, Pool[8] memory pools) internal view returns (Reserve[8] memory reserves);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isDeposit`|`bool`|true if deposit eth, false if redeem|
|`pools`|`Pool[8]`|5 element array of Pool structs populated with pool addresses|


### _optimalRouteOut

*sorts possible swaps by best price, then assigns optimal split*


```solidity
function _optimalRouteOut(
    bool useQueue,
    bool isDeposit,
    uint256 amountIn,
    uint256 amountOutMin,
    Reserve[8] memory reserves
)
    internal
    view
    returns (uint256[8] memory amountsIn, uint256[8] memory amountsOut);
```

### _scalingFactor


```solidity
function _scalingFactor(bool token0) internal view returns (uint256 scalingFactor);
```

### _getScaledTokenBalance

*Reads the balance of a token from the balancer vault and returns the scaled amount. Smaller storage access
compared to getVault().getPoolTokens().
Copied from the 3CLP *except* that for the 2CLP, the scalingFactor is interpreted as a regular integer, not a
FixedPoint number. This is an inconsistency between the base contracts.*


```solidity
function _getScaledTokenBalance(address token, uint256 scalingFactor) internal view returns (uint256 balance);
```

### _getAllBalances

*Get all balances in the pool, scaled by the appropriate scaling factors, in a relatively gas-efficient way.
Essentially copied from the 3CLP.*


```solidity
function _getAllBalances() internal view returns (uint256[] memory balances);
```

### balancerAmountOut


```solidity
function balancerAmountOut(
    bool isDeposit,
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    IGyroECLPMath.Vector2 memory inv
)
    internal
    view
    returns (uint256 amountOut);
```

### amountOutCall


```solidity
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
    returns (uint256 amountOut);
```

### _splitSwapOut

assigns optimal route for maximum amount out, given pool reserves


```solidity
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
    returns (uint256[8] memory amountsIn, uint256[8] memory amountsOut);
```

### amountToSync


```solidity
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
    returns (uint256 amountInToSync, uint256 amountOut);
```

### uniswapV3SwapCallback

*Callback for Uniswap V3 pool.*


```solidity
function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount0Delta`|`int256`|amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)|
|`amount1Delta`|`int256`|amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)|
|`data`|`bytes`|tokenIn,tokenOut and fee packed bytes|


### ensure

Ensures deadline is not passed, otherwise revert.

*Modifier has been replaced with a function for gas efficiency*


```solidity
function ensure(uint256 deadline) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`deadline`|`uint256`|Unix timestamp in seconds for transaction to execute before|


### _swapSingle

*single swap for uni v2 pair. Requires the initial amount to have already been sent to the first pair.*


```solidity
function _swapSingle(bool isReverse, address to, address pair, uint256 amountOut) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isReverse`|`bool`|true if token0 == tokenOut|
|`to`|`address`|swap recipient|
|`pair`|`address`|pair address|
|`amountOut`|`uint256`|expected amount out|


### _swapUniV3

*single swap for uni v3 pool*


```solidity
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
    returns (uint256 amountInActual, uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isReverse`|`bool`|true if token0 == tokenOut|
|`fee`|`uint24`|fee of pool as a ratio of 1000000|
|`to`|`address`|swap recipient|
|`tokenIn`|`address`|token in address|
|`tokenOut`|`address`|token out address|
|`pair`|`address`|pair address|
|`amountIn`|`uint256`|amount of tokenIn|


### _swap

*Internal core swap. Requires the initial amount to have already been sent to the first pair (for v2 pairs).*


```solidity
function _swap(bool useQueue, address to, uint256 deadline, Swap memory swaps) internal virtual returns (uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`useQueue`|`bool`|Use queue or not for withdrawals|
|`to`|`address`|Address of receiver|
|`deadline`|`uint256`|timstamp of expiry|
|`swaps`|`Swap`|Array of user swap data|


### _asmSwap

Internal call to perform single swap


```solidity
function _asmSwap(address pair, uint256 amount0Out, uint256 amount1Out, address to) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pair`|`address`|Address of pair to swap in|
|`amount0Out`|`uint256`|AmountOut for token0 of pair|
|`amount1Out`|`uint256`|AmountOut for token1 of pair|
|`to`|`address`|Address of receiver|


### _decode

De-compresses 2 addresses and 1 uint24 from byte stream (len = 43)


```solidity
function _decode(bytes memory data) internal pure returns (address a, address b, uint24 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes`|Compressed byte stream|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`a`|`address`|Address of first param|
|`b`|`address`|Address of second param|
|`fee`|`uint24`|(0.3% => 3000 ...)|


### _isZero

Uint256 zero check gas saver


```solidity
function _isZero(uint256 value) internal pure returns (bool boolValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|Number to check|


### _isNonZero

Uint256 not zero check gas saver


```solidity
function _isNonZero(uint256 value) internal pure returns (bool boolValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|Number to check|


### _inc

Unchecked increment gas saver for loops


```solidity
function _inc(uint256 i) internal pure returns (uint256 result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`uint256`|Number to increment|


### _dec

Unchecked decrement gas saver for loops


```solidity
function _dec(uint256 i) internal pure returns (uint256 result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`uint256`|Number to decrement|


### receive

Function to receive Ether. msg.data must be empty


```solidity
receive() external payable;
```

### fallback

Fallback function is called when msg.data is not empty


```solidity
fallback() external payable;
```

### changeGov


```solidity
function changeGov(address newGov) external;
```

### changePoolId


```solidity
function changePoolId(bytes32 newPoolId) external;
```

### changeCurvePool


```solidity
function changeCurvePool(address newCurvePool) external;
```

### changeUniV3Caps


```solidity
function changeUniV3Caps(uint256[3] calldata caps) external;
```

### sweep

Sweep dust tokens and eth to recipient


```solidity
function sweep(address[] calldata tokens, address recipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`address[]`|Array of token addresses|
|`recipient`|`address`|Address of recipient|


## Errors
### Expired

```solidity
error Expired();
```

### ZeroAmount

```solidity
error ZeroAmount();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

### ExecuteNotAuthorized

```solidity
error ExecuteNotAuthorized();
```

### InsufficientOutputAmount

```solidity
error InsufficientOutputAmount();
```

## Structs
### Reserve
struct for pool reserves


```solidity
struct Reserve {
    uint256 reserveIn;
    uint256 reserveOut;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`reserveIn`|`uint256`|amount of reserves (or virtual reserves) in pool for tokenIn|
|`reserveOut`|`uint256`|amount of reserves (or virtual reserves) in pool for tokenOut|

