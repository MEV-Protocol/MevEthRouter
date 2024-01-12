# IMevEth
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IMevEth.sol)


## Functions
### fraction


```solidity
function fraction() external view returns (uint128 elastic, uint128 base);
```

### convertToAssets


```solidity
function convertToAssets(uint256 shares) external view returns (uint256 assets);
```

### convertToShares


```solidity
function convertToShares(uint256 assets) external view returns (uint256 shares);
```

### previewRedeem


```solidity
function previewRedeem(uint256 shares) external view returns (uint256 assets);
```

### previewWithdraw


```solidity
function previewWithdraw(uint256 assets) external view returns (uint256 shares);
```

### previewDeposit


```solidity
function previewDeposit(uint256 assets) external view returns (uint256 shares);
```

### deposit


```solidity
function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);
```

### redeem


```solidity
function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
```

### withdrawQueue


```solidity
function withdrawQueue(uint256 assets, address receiver, address owner) external returns (uint256 shares);
```

