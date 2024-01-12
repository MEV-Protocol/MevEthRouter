# IGyroECLPMath
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IGyroECLPMath.sol)


## Functions
### calcOutGivenIn


```solidity
function calcOutGivenIn(
    uint256[] memory balances,
    uint256 amountIn,
    bool tokenInIsToken0,
    Params memory params,
    DerivedParams memory derived,
    Vector2 memory invariant
)
    external
    pure
    returns (uint256 amountOut);
```

### calculateInvariantWithError


```solidity
function calculateInvariantWithError(uint256[] memory balances, Params memory params, DerivedParams memory derived) external pure returns (int256, int256);
```

### calculateInvariant


```solidity
function calculateInvariant(uint256[] memory balances, Params memory params, DerivedParams memory derived) external pure returns (uint256 uinvariant);
```

## Structs
### Params

```solidity
struct Params {
    int256 alpha;
    int256 beta;
    int256 c;
    int256 s;
    int256 lambda;
}
```

### DerivedParams

```solidity
struct DerivedParams {
    Vector2 tauAlpha;
    Vector2 tauBeta;
    int256 u;
    int256 v;
    int256 w;
    int256 z;
    int256 dSq;
}
```

### Vector2

```solidity
struct Vector2 {
    int256 x;
    int256 y;
}
```

