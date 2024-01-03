# Calculating Uniswap V3 virtual reserves

Integrating V3 pools into optimal split route math requires converting given liquidity values to virtual reserves. From the [whitepaper](https://uniswap.org/whitepaper-v3.pdf), virtual reserves can be calculated with the following formulae:

$$ x = {L \over \sqrt{P}} $$

$$ y = {L * \sqrt{P}} $$

Where L is the liquidity and P is the given price.

[Liquidity (L) can be attained directly from the pool.](https://docs.uniswap.org/protocol/reference/core/interfaces/pool/IUniswapV3PoolState)

```solidity
function liquidity() external view returns (uint256);
```

[Price (P) can be derived from `sqrtPriceX96`, given in `slot0`](https://docs.uniswap.org/protocol/reference/core/interfaces/pool/IUniswapV3PoolState)

```solidity
function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)
```

[`SqrtPriceX96` is convertable to SqrtPrice with the following](https://docs.uniswap.org/sdk/guides/fetching-prices)

$$ {sqrtPriceX96} = \sqrt{P} * 2 ** 96 $$

Therefore, virtual reserves are calculated with:

$$ x = {L * 2^{96} \over {sqrtPriceX96}} $$

$$ y = {L * {sqrtPriceX96} \over 2^{96}} $$