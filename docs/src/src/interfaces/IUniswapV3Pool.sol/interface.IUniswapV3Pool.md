# IUniswapV3Pool
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IUniswapV3Pool.sol)

A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
to the ERC20 specification

*The pool interface is broken up into many smaller pieces*


## Functions
### factory

The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface


```solidity
function factory() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The contract address|


### token0

The first of the two tokens of the pool, sorted by address


```solidity
function token0() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The token contract address|


### token1

The second of the two tokens of the pool, sorted by address


```solidity
function token1() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The token contract address|


### fee

The pool's fee in hundredths of a bip, i.e. 1e-6


```solidity
function fee() external view returns (uint24);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint24`|The fee|


### slot0

The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
when accessed externally.


```solidity
function slot0() external view returns (uint160 sqrtPriceX96, int24 tick);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sqrtPriceX96`|`uint160`|The current price of the pool as a sqrt(token1/token0) Q64.96 value tick The current tick of the pool, i.e. according to the last tick transition that was run. This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick boundary. observationIndex The index of the last oracle observation that was written, observationCardinality The current maximum number of observations stored in the pool, observationCardinalityNext The next maximum number of observations, to be updated when the observation. feeProtocol The protocol fee for both tokens of the pool. Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0 is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee. unlocked Whether the pool is currently locked to reentrancy|
|`tick`|`int24`||


### liquidity

The currently in range liquidity available to the pool

*This value has no relationship to the total liquidity across all ticks*


```solidity
function liquidity() external view returns (uint128);
```

### swap

Swap token0 for token1, or token1 for token0

*The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback*


```solidity
function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
)
    external
    returns (int256 amount0, int256 amount1);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The address to receive the output of the swap|
|`zeroForOne`|`bool`|The direction of the swap, true for token0 to token1, false for token1 to token0|
|`amountSpecified`|`int256`|The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)|
|`sqrtPriceLimitX96`|`uint160`|The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap|
|`data`|`bytes`|Any data to be passed through to the callback|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount0`|`int256`|The delta of the balance of token0 of the pool, exact when negative, minimum when positive|
|`amount1`|`int256`|The delta of the balance of token1 of the pool, exact when negative, minimum when positive|


