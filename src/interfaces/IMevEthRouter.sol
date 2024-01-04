// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMevEthRouter {
    /// @notice struct for pool swap info
    /// @param pair pair / pool address (sushi, univ2, univ3 (3 pools))
    /// @param amountIn amount In for swap
    /// @param amountOut amount Out for swap
    struct Pool {
        address pair;
        uint256 amountIn;
        uint256 amountOut;
    }

    /// @notice struct for swap info
    /// @param isDeposit true if deposit eth, false if redeem
    /// @param tokenIn address of token In
    /// @param tokenOut address of token Out
    /// @param pools 5 element array of pool split swap info
    struct Swap {
        bool isDeposit;
        address tokenIn;
        address tokenOut;
        Pool[8] pools; // 8 pools (sushi, univ2, univ3 (3 pools), mevEth, Balancer Gyro ECLP, Curve V2)
    }

    function stakeEthForMevEth(address receiver, uint256 amountIn, uint256 amountOutMin, uint256 deadline) external payable returns (uint256 shares);
    function stakeEthForMevEthRaw(
        address receiver,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        Swap calldata swaps
    )
        external
        payable
        returns (uint256 shares);
    function redeemMevEthForEth(bool useQueue, address receiver, uint256 shares, uint256 amountOutMin, uint256 deadline) external returns (uint256 assets);
    function redeemMevEthForEthRaw(
        bool useQueue,
        address receiver,
        uint256 shares,
        uint256 amountOutMin,
        uint256 deadline,
        Swap calldata swaps
    )
        external
        returns (uint256 assets);
    function getStakeRoute(uint256 amountIn, uint256 amountOutMin) external returns (Swap memory swaps);
    function getRedeemRoute(bool useQueue, uint256 amountIn, uint256 amountOutMin) external returns (Swap memory swaps);
}
