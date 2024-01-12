/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { MevEthRouter } from "../src/MevEthRouter.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { IMevEth } from "../src/interfaces/IMevEth.sol";
import { IMevEthRouter } from "../src/interfaces/IMevEthRouter.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title MevEthRouter2Test use different fork for cross check
contract MevEthRouter2Test is DSTest {
    using stdStorage for StdStorage;

    string RPC_ETH_MAINNET = vm.envString("RPC_MAINNET");
    uint256 FORK_ID;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    MevEthRouter router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IMevEth internal constant MEVETH = IMevEth(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

    IWETH weth = IWETH(WETH);
    uint256 minLiquidity = uint256(1000);

    function setUp() public {
        FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);
        router = new MevEthRouter(0x617c8dE5BdE54ffbb8d92716CC947858cA38f582);
    }

    function writeTokenBalance(address who, address token, uint256 amt) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    receive() external payable { }

    /// @dev Fuzz test amountOut, Stake and redeem
    function testStakeAndRedeem(uint80 amountIn) external {
        vm.assume(amountIn > 0.1 ether);
        vm.assume(amountIn < 100_000 ether);
        vm.deal(address(this), amountIn);
        // test getting swap route
        bytes memory input = abi.encodeWithSelector(router.amountOutStake.selector, amountIn);
        (, bytes memory data) = address(router).staticcall(input);
        (uint256 amountOut, IMevEthRouter.Swap memory swaps) = abi.decode(data, (uint256, IMevEthRouter.Swap));
        assertGt(amountOut, MEVETH.previewDeposit(amountIn) * 999 / 1000);
        // test stake
        uint256 shares = router.stakeEthForMevEth{ value: amountIn }(address(this), amountIn, amountOut * 99 / 100, block.timestamp, swaps);
        assertGt(shares, amountOut * 99 / 100);
        // test redeem route
        bool useQueue;
        if (amountIn > 15 ether) {
            useQueue = true;
        }
        input = abi.encodeWithSelector(router.amountOutRedeem.selector, useQueue, shares);
        (, data) = address(router).staticcall(input);
        (amountOut, swaps) = abi.decode(data, (uint256, IMevEthRouter.Swap));
        assertGt(amountOut, MEVETH.previewRedeem(shares) * 95 / 100);
        // test redeem
        ERC20(address(MEVETH)).approve(address(router), shares);
        uint256 assets = router.redeemMevEthForEth(useQueue, address(this), shares, amountOut * 99 / 100, block.timestamp, swaps);
        assertGt(assets, 0);
    }
}
