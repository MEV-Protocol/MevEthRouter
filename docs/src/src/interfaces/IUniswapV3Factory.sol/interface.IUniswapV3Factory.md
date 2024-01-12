# IUniswapV3Factory
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IUniswapV3Factory.sol)

The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees


## Functions
### owner

Returns the current owner of the factory

*Can be changed by the current owner via setOwner*


```solidity
function owner() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the factory owner|


### feeAmountTickSpacing

Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled

*A fee amount can never be removed, so this value should be hard coded or cached in the calling context*


```solidity
function feeAmountTickSpacing(uint24 fee) external view returns (int24);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint24`|The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int24`|The tick spacing|


### getPool

Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist

*tokenA and tokenB may be passed in either token0/token1 or token1/token0 order*


```solidity
function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenA`|`address`|The contract address of either token0 or token1|
|`tokenB`|`address`|The contract address of the other token|
|`fee`|`uint24`|The fee collected upon every swap in the pool, denominated in hundredths of a bip|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|The pool address|


### createPool

Creates a pool for the given two tokens and fee

*tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
are invalid.*


```solidity
function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenA`|`address`|One of the two tokens in the desired pool|
|`tokenB`|`address`|The other of the two tokens in the desired pool|
|`fee`|`uint24`|The desired fee for the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|The address of the newly created pool|


### setOwner

Updates the owner of the factory

*Must be called by the current owner*


```solidity
function setOwner(address _owner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The new owner of the factory|


### enableFeeAmount

Enables a fee amount with the given tickSpacing

*Fee amounts may never be removed once enabled*


```solidity
function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint24`|The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)|
|`tickSpacing`|`int24`|The spacing between ticks to be enforced for all pools created with the given fee amount|


## Events
### OwnerChanged
Emitted when the owner of the factory is changed


```solidity
event OwnerChanged(address indexed oldOwner, address indexed newOwner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldOwner`|`address`|The owner before the owner was changed|
|`newOwner`|`address`|The owner after the owner was changed|

### PoolCreated
Emitted when a pool is created


```solidity
event PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|The first token of the pool by address sort order|
|`token1`|`address`|The second token of the pool by address sort order|
|`fee`|`uint24`|The fee collected upon every swap in the pool, denominated in hundredths of a bip|
|`tickSpacing`|`int24`|The minimum number of ticks between initialized ticks|
|`pool`|`address`|The address of the created pool|

### FeeAmountEnabled
Emitted when a new fee amount is enabled for pool creation via the factory


```solidity
event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint24`|The enabled fee, denominated in hundredths of a bip|
|`tickSpacing`|`int24`|The minimum number of ticks between initialized ticks for pools created with the given fee|

