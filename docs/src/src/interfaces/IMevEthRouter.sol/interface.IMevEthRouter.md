# IMevEthRouter
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IMevEthRouter.sol)


## Functions
### amountOutStake


```solidity
function amountOutStake(uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps);
```

### amountOutRedeem


```solidity
function amountOutRedeem(bool useQueue, uint256 amountIn) external view returns (uint256 amountOut, Swap memory swaps);
```

### stakeEthForMevEth


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

### redeemMevEthForEth


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

## Structs
### Pool
struct for pool swap info


```solidity
struct Pool {
    address pair;
    uint256 amountIn;
    uint256 amountOut;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`pair`|`address`|pair / pool address (sushi, univ2, univ3 (3 pools))|
|`amountIn`|`uint256`|amount In for swap|
|`amountOut`|`uint256`|amount Out for swap|

### Swap
struct for swap info


```solidity
struct Swap {
    bool isDeposit;
    address tokenIn;
    address tokenOut;
    Pool[8] pools;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`isDeposit`|`bool`|true if deposit eth, false if redeem|
|`tokenIn`|`address`|address of token In|
|`tokenOut`|`address`|address of token Out|
|`pools`|`Pool[8]`|5 element array of pool split swap info|

