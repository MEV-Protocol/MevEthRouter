# ICurveV2Pool
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/ICurveV2Pool.sol)


## Functions
### exchange


```solidity
function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth, address receiver) external payable returns (uint256 dy);
```

### calc_token_amount


```solidity
function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);
```

### token


```solidity
function token() external view returns (address);
```

### coins


```solidity
function coins(uint256 arg0) external view returns (address);
```

### balances


```solidity
function balances(uint256 arg0) external view returns (uint256);
```

### get_dy


```solidity
function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
```

