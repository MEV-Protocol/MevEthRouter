// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMevEth {
    function fraction() external view returns (uint128 elastic, uint128 base);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function withdrawQueue(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}
