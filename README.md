# mevETH Router ![Foundry](https://github.com/manifoldfinance/MevEthRouter/actions/workflows/forge.yaml/badge.svg)

### Optimal route for mevETH Deposit / Swap / Withdraw

Pools
- Curve
- Balancer
- Uniswap V3 0.30%
- Uniswap V3 0.05%
- Uniswap V3 1.00%
- Sushiswap
- Uniswap V2

MevEth routes:
- deposit / mint
- withdraw / redeem

[Uniswap V3 virtual reserves calculation](docs/virtual-reserves.md)

## Developer Setup
Copy `.env-example` to `.env` and fill in `ETH_RPC_URL`.
```sh
source .env
```

## Build
```sh
forge build
```

## Fuzz tests

Fuzz test all methods on `MevEthRouter` produce better results than Deposit / Redeem.
```sh
forge test -vvv
```


## Test deploy
Ethereum mainnet:
```sh
forge script script/Deploy.s.sol:DeployScript --rpc-url $ETH_RPC_URL
```


## Deploy and verify on etherscan
Fill in `PRIVATE_KEY` and `ETHERSCAN_KEY` in `.env`.

```sh
./script/deploy-eth.sh
```

### V1 ✓

- [x] Optimal depsoit / withdraw / swap route for ETH <> mevETH
- [x] Split swaps between Sushiswap, Uniswap V2 and Uniswap V3, Balancer, Curve, MevEth funcs
- [x] Testing
- [x] Deployment scripts
- [x] Redeem route with queue toggle and slippage tolerance
- [ ] Documentation of derived math and code
- [ ] Gas optimization

### V2 

- [ ] Include yETH
- [ ] Include multi hop routes eg frxETH <> mevETH <> ETH
- [ ] Backruns
- [ ] Include stakerBPT / CPT routes and backruns

