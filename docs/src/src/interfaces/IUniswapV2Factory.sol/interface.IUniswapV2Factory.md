# IUniswapV2Factory
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IUniswapV2Factory.sol)


## Functions
### getPair


```solidity
function getPair(address tokenA, address tokenB) external view returns (address pair);
```

### allPairs


```solidity
function allPairs(uint256) external view returns (address pair);
```

### allPairsLength


```solidity
function allPairsLength() external view returns (uint256);
```

### createPair


```solidity
function createPair(address tokenA, address tokenB) external returns (address pair);
```

### pairCodeHash


```solidity
function pairCodeHash() external pure returns (bytes32);
```

