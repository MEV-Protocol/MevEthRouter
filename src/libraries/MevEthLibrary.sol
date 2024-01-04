/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";

/// @title MevEthLibrary
/// @author Manifold FInance
/// @notice Optimal MEV library to support MevEthRouter
library MevEthLibrary {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    /// @dev Minimum pool liquidity to interact with
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    /// @dev calculate uinswap v3 pool address
    /// @param token0 address of token0
    /// @param token1 address of token1
    /// @param fee pool fee as ratio of 1000000
    function uniswapV3PoolAddress(address token0, address token1, uint24 fee) internal pure returns (address pool) {
        // NB moving constants to here seems more gas efficient
        bytes32 POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        address UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        bytes32 pubKey = keccak256(abi.encodePacked(hex"ff", UNIV3_FACTORY, keccak256(abi.encode(token0, token1, fee)), POOL_INIT_CODE_HASH));

        //bytes32 to address:
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, pubKey)
            pool := mload(ptr)
        }
    }

    /// @dev get fee for pool as a fraction of 1000000 (i.e. 0.3% -> 3000)
    /// @param index Reference order is hard coded as sushi, univ2, univ3 (0.3%), univ3 (0.05%), univ3 (1%)
    function getFee(uint256 index) internal pure returns (uint256) {
        if (index < 3) return 3000;
        // sushi, univ2 and 0.3% univ3
        else if (index == 3) return 500;
        else if (index == 4) return 10_000;
        else if (index == 5) return 200; // Balancer Gyro

        else if (index == 6) return 200; // Curve fee

        else return 100; // meveth withdraw fee
    }

    /// @custom:assembly Sort tokens, zero address check
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;

        assembly ("memory-safe") {
            switch lt(shl(96, tokenA), shl(96, tokenB))
            // sort tokens
            case 0 {
                token0 := tokenB
                token1 := tokenA
            }
            default {
                token0 := tokenA
                token1 := tokenB
            }
            isZeroAddress := iszero(token0)
        }
        if (isZeroAddress) revert ZeroAddress();
    }

    /// @custom:assembly Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function _asmPairFor(address factory, address token0, address token1, bytes32 factoryHash) internal pure returns (address pair) {
        // There is one contract for every combination of tokens,
        // which is deployed using CREATE2.
        // The derivation of this address is given by:
        //   address(keccak256(abi.encodePacked(
        //       bytes(0xFF),
        //       address(UNISWAP_FACTORY_ADDRESS),
        //       keccak256(abi.encodePacked(token0, token1)),
        //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
        //   )));
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, shl(96, token0))
            mstore(add(ptr, 0x14), shl(96, token1))
            let salt := keccak256(ptr, 0x28) // keccak256(token0, token1)
            mstore(ptr, 0xFF00000000000000000000000000000000000000000000000000000000000000) // buffered 0xFF prefix
            mstore(add(ptr, 0x01), shl(96, factory)) // factory address prefixed
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), factoryHash) // factory init code hash
            pair := keccak256(ptr, 0x55)
        }
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * uint256(997);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * uint256(1000)) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOutFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 fee) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * (1_000_000 - fee);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * 1_000_000) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @dev checks codesize for contract existence
    /// @param _addr address of contract to check
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (_isNonZero(size));
    }

    /**
     * @dev Returns the address of a Pool's contract.
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getBalancerPoolAddress(bytes32 _poolId) internal pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return address(uint160(uint256(_poolId) >> (12 * 8)));
    }

    /// @dev insert sorted index of amount array (in ascending order)
    function _sortArray(uint256[8] memory _data) internal pure returns (uint256[8] memory index) {
        uint256[8] memory data;
        for (uint256 i; i < 8; i++) {
            data[i] = _data[i];
        }
        index = [uint256(0), uint256(1), uint256(2), uint256(3), uint256(4), uint256(5), uint256(6), uint256(7)];
        for (uint256 i = 1; i < 8; i++) {
            uint256 key = data[i];
            uint256 keyIndex = index[i];
            uint256 j = i;
            while (_isNonZero(j) && (data[_dec(j)] > key)) {
                data[j] = data[_dec(j)];
                index[j] = index[_dec(j)];
                j = _dec(j);
            }
            data[j] = key;
            index[j] = keyIndex;
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @dev Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @dev Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @dev Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}
