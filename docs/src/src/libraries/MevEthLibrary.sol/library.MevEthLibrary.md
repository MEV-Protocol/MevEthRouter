# MevEthLibrary
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/libraries/MevEthLibrary.sol)

**Author:**
Manifold FInance

SPDX-License-Identifier: UNLICENSED

Optimal MEV library to support MevEthRouter


## State Variables
### MINIMUM_LIQUIDITY
*Minimum pool liquidity to interact with*


```solidity
uint256 internal constant MINIMUM_LIQUIDITY = 1000;
```


## Functions
### uniswapV3PoolAddress

*calculate uinswap v3 pool address*


```solidity
function uniswapV3PoolAddress(address token0, address token1, uint24 fee) internal pure returns (address pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|address of token0|
|`token1`|`address`|address of token1|
|`fee`|`uint24`|pool fee as ratio of 1000000|


### getFee

*get fee for pool as a fraction of 1000000 (i.e. 0.3% -> 3000)*


```solidity
function getFee(uint256 index) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`index`|`uint256`|Reference order is hard coded as sushi, univ2, univ3 (0.3%), univ3 (0.05%), univ3 (1%)|


### sortTokens

Returns sorted token addresses, used to handle return values from pairs sorted in this order

*Require replaced with revert custom error*


```solidity
function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenA`|`address`|Pool token|
|`tokenB`|`address`|Pool token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|First token in pool pair|
|`token1`|`address`|Second token in pool pair|


### _asmPairFor

Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens

*Factory passed in directly because we have multiple factories. Format changes for new solidity spec.*


```solidity
function _asmPairFor(address factory, address token0, address token1, bytes32 factoryHash) internal pure returns (address pair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`factory`|`address`|Factory address for dex|
|`token0`|`address`|Pool token|
|`token1`|`address`|Pool token|
|`factoryHash`|`bytes32`|Init code hash for factory|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pair`|`address`|Pair pool address|


### getAmountOut

Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves

*Require replaced with revert custom error*


```solidity
function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`|Amount of token in|
|`reserveIn`|`uint256`|Reserves for token in|
|`reserveOut`|`uint256`|Reserves for token out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Amount of token out returned|


### getAmountOutFee

Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves

*Require replaced with revert custom error*


```solidity
function getAmountOutFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 fee) internal pure returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`|Amount of token in|
|`reserveIn`|`uint256`|Reserves for token in|
|`reserveOut`|`uint256`|Reserves for token out|
|`fee`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Amount of token out returned|


### isContract

*checks codesize for contract existence*


```solidity
function isContract(address _addr) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_addr`|`address`|address of contract to check|


### _getBalancerPoolAddress

*Returns the address of a Pool's contract.
Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.*


```solidity
function _getBalancerPoolAddress(bytes32 _poolId) internal pure returns (address);
```

### _sortArray

*insert sorted index of amount array (in ascending order)*


```solidity
function _sortArray(uint256[8] memory _data) internal pure returns (uint256[8] memory index);
```

### _isZero

*Uint256 zero check gas saver*


```solidity
function _isZero(uint256 value) internal pure returns (bool boolValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|Number to check|


### _isNonZero

*Uint256 not zero check gas saver*


```solidity
function _isNonZero(uint256 value) internal pure returns (bool boolValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|Number to check|


### _dec

*Unchecked decrement gas saver for loops*


```solidity
function _dec(uint256 i) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`uint256`|Number to decrement|


## Errors
### Overflow

```solidity
error Overflow();
```

### ZeroAmount

```solidity
error ZeroAmount();
```

### InvalidPath

```solidity
error InvalidPath();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

### IdenticalAddresses

```solidity
error IdenticalAddresses();
```

### InsufficientLiquidity

```solidity
error InsufficientLiquidity();
```

