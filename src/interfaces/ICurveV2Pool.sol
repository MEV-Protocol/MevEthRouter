// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICurveV2Pool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth, address receiver) external payable returns (uint256 dy);
    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);
    function token() external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}
