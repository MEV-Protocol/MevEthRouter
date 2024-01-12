# IVault
[Git Source](https://github.com/manifoldfinance/MevEthRouter/blob/7ae7f0bb6d26c35a3dd7bd22f9b451cb05d17d36/src/interfaces/IVault.sol)


## Functions
### getPoolTokenInfo

*Returns detailed information for a Pool's registered token.
`cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
equals the sum of `cash` and `managed`.
Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
`managed` or `total` balance to be greater than 2^112 - 1.
`lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
change for this purpose, and will update `lastChangeBlock`.
`assetManager` is the Pool's token Asset Manager.*


```solidity
function getPoolTokenInfo(bytes32 poolId, address token) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);
```

### getPoolTokens

*Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
the tokens' `balances` changed.
The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
order as passed to `registerTokens`.
Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
instead.*


```solidity
function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
```

### joinPool

*Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
Pool shares.
If the caller is not `sender`, it must be an authorized relayer for them.
The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
these maximums.
If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
this mechanism, the address sentinel value (the zero address) must be passed in the `assets` array instead of the
WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
back to the caller (not the sender, which is important for relayers).
`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
`assets` array might not be sorted. Pools with no registered tokens cannot be joined.
If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
withdrawn from Internal Balance: attempting to do so will trigger a revert.
This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
directly to the Pool's contract, as is `recipient`.
Emits a `PoolBalanceChanged` event.*


```solidity
function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
```

### exitPool

*Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
`getPoolTokenInfo`).
If the caller is not `sender`, it must be an authorized relayer for them.
The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
it just enforces these minimums.
If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
enable this mechanism, the address sentinel value (the zero address) must be passed in the `assets` array instead
of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
do so will trigger a revert.
`minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
`tokens` array. This array must match the Pool's registered tokens.
This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
passed directly to the Pool's contract.
Emits a `PoolBalanceChanged` event.*


```solidity
function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;
```

### swap

*Performs a swap with a single Pool.
If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
taken from the Pool, which must be greater than or equal to `limit`.
If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
sent to the Pool, which must be less than or equal to `limit`.
Internal Balance usage and the recipient are determined by the `funds` struct.
Emits a `Swap` event.*


```solidity
function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external payable returns (uint256);
```

### batchSwap

*Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
the amount of tokens sent to or received from the Pool, depending on the `kind` value.
Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
the same index in the `assets` array.
Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
`amountOut` depending on the swap kind.
Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
or the address sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
or unwrapped from WETH by the Vault.
Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
the minimum or maximum amount of each token the vault is allowed to transfer.
`batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
equivalent `swap` call.
Emits `Swap` events.*


```solidity
function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    address[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
)
    external
    payable
    returns (int256[] memory);
```

### queryBatchSwap

*Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
receives are the same that an equivalent `batchSwap` call would receive.
Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
approve them for the Vault, or even know a user's address.
Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
eth_call instead of eth_sendTransaction.*


```solidity
function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    address[] memory assets,
    FundManagement memory funds
)
    external
    returns (int256[] memory assetDeltas);
```

## Events
### Swap
*Emitted for each individual swap performed by `swap` or `batchSwap`.*


```solidity
event Swap(bytes32 indexed poolId, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
```

## Structs
### JoinPoolRequest

```solidity
struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}
```

### ExitPoolRequest

```solidity
struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}
```

### SingleSwap
*Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
the `kind` value.
`assetIn` and `assetOut` are either token addresses, or the address sentinel value for ETH (the zero address).
Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
used to extend swap behavior.*


```solidity
struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}
```

### BatchSwapStep
*Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
`assets` array passed to that function, and ETH assets are converted to WETH.
If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
from the previous swap, depending on the swap kind.
The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
used to extend swap behavior.*


```solidity
struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}
```

### FundManagement
*All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
`recipient` account.
If the caller is not `sender`, it must be an authorized relayer for them.
If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
`joinPool`.
If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
transferred. This matches the behavior of `exitPool`.
Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
revert.*


```solidity
struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}
```

## Enums
### SwapKind

```solidity
enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}
```

