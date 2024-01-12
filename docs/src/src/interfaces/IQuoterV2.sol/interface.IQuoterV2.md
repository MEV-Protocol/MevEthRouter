# IQuoterV2
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IQuoterV2.sol)

Supports quoting the calculated amounts from exact input or exact output swaps.

For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.

*These functions are not marked view because they rely on calling non-view functions and reverting
to compute the result. They are also not gas efficient and should not be called on-chain.*


## Functions
### quoteExactInput

Returns the amount out received for a given exact input swap without executing the swap


```solidity
function quoteExactInput(
    bytes memory path,
    uint256 amountIn
)
    external
    returns (uint256 amountOut, uint160[] memory sqrtPriceX96AfterList, uint32[] memory initializedTicksCrossedList, uint256 gasEstimate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`path`|`bytes`|The path of the swap, i.e. each token pair and the pool fee|
|`amountIn`|`uint256`|The amount of the first token to swap|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|The amount of the last token that would be received|
|`sqrtPriceX96AfterList`|`uint160[]`|List of the sqrt price after the swap for each pool in the path|
|`initializedTicksCrossedList`|`uint32[]`|List of the initialized ticks that the swap crossed for each pool in the path|
|`gasEstimate`|`uint256`|The estimate of the gas that the swap consumes|


### quoteExactInputSingle

Returns the amount out received for a given exact input but for a swap of a single pool


```solidity
function quoteExactInputSingle(QuoteExactInputSingleParams memory params) external returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`QuoteExactInputSingleParams`|The params for the quote, encoded as `QuoteExactInputSingleParams` tokenIn The token being swapped in tokenOut The token being swapped out fee The fee of the token pool to consider for the pair amountIn The desired input amount sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|The amount of `tokenOut` that would be received|


## Structs
### QuoteExactInputSingleParams

```solidity
struct QuoteExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
}
```

