// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICurveV2Pool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth, address receiver) external payable returns (uint256 dy);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, bool use_eth) external payable returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, bool use_eth, address receiver) external payable returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts, bool use_eth) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts, bool use_eth, address receiver) external;

    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external returns (uint256);

    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount, bool use_eth) external returns (uint256);

    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount, bool use_eth, address receiver) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

    function lp_price() external view returns (uint256);

    function token() external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 dx) external returns (uint256);
}
