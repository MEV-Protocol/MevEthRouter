# IGyro
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IGyro.sol)


## Functions
### getPoolId


```solidity
function getPoolId() external view returns (bytes32);
```

### getVault


```solidity
function getVault() external view returns (address);
```

### getInvariant


```solidity
function getInvariant() external view returns (uint256);
```

### getECLPParams


```solidity
function getECLPParams() external view returns (IGyroECLPMath.Params memory params, IGyroECLPMath.DerivedParams memory d);
```

