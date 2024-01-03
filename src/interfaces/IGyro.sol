// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IGyroECLPMath.sol";

interface IGyro {
    function getPoolId() external view returns (bytes32);
    function getVault() external view returns (address);
    function getInvariant() external view returns (uint256);
    function getECLPParams() external view returns (IGyroECLPMath.Params memory params, IGyroECLPMath.DerivedParams memory d);
}
