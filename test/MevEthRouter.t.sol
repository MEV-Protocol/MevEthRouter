/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { MevEthRouter } from "../src/MevEthRouter.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { IMevEth } from "../src/interfaces/IMevEth.sol";
import { IMevEthRouter } from "../src/interfaces/IMevEthRouter.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title MevEthRouterTest
contract MevEthRouterTest is DSTest {
    using stdStorage for StdStorage;

    string RPC_ETH_MAINNET = vm.envString("RPC_MAINNET");
    uint256 FORK_ID;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    MevEthRouter router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IMevEth internal constant MEVETH = IMevEth(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

    IWETH weth = IWETH(WETH);
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 routerOld = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    uint256 minLiquidity = uint256(1000);

    function setUp() public {
        FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);
        router = new MevEthRouter(0x617c8dE5BdE54ffbb8d92716CC947858cA38f582);
    }

    function writeTokenBalance(address who, address token, uint256 amt) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    receive() external payable { }

    function testStakeEthRaw(uint80 amountIn) external {
        vm.assume(amountIn > 0.1 ether);
        vm.assume(amountIn < 100_000 ether);
        // uint256 amountIn = 100 ether;
        vm.deal(address(this), amountIn);
        uint256 amountOutMin = MEVETH.previewDeposit(amountIn) * 99 / 100;
        IMevEthRouter.Swap memory swaps = router.getStakeRoute(amountIn, amountOutMin);
        uint256 shares = router.stakeEthForMevEthRaw{ value: amountIn }(address(this), amountIn, amountOutMin, block.timestamp, swaps);
        assertGt(shares, 0);
    }

    function testRedeemEthRaw(uint80 amountIn) external {
        vm.assume(amountIn > 2 ether);
        vm.assume(amountIn < 10_000 ether);
        // uint256 amountIn = 100 ether;
        vm.deal(address(this), amountIn);
        uint256 shares = router.stakeEthForMevEth{ value: amountIn }(address(this), amountIn, 1, block.timestamp);
        uint256 amountOutMin = 1;
        ERC20(address(MEVETH)).approve(address(router), shares);
        IMevEthRouter.Swap memory swaps = router.getRedeemRoute(false, shares / 2, amountOutMin);
        uint256 assets = router.redeemMevEthForEthRaw(false, address(this), shares / 2, amountOutMin, block.timestamp, swaps);
        assertGt(assets, 0);
        swaps = router.getRedeemRoute(true, shares / 2, amountOutMin);
        assets = router.redeemMevEthForEthRaw(true, address(this), shares / 2, amountOutMin, block.timestamp, swaps);
        assertGt(assets, 0);
    }

    function testStakeEth(uint80 amountIn) external {
        vm.assume(amountIn > 0.1 ether);
        vm.assume(amountIn < 100000 ether);
        // uint256 amountIn = 100 ether;
        vm.deal(address(this), amountIn);
        uint256 amountOutMin = MEVETH.previewDeposit(amountIn) * 99 / 100;
        uint256 shares = router.stakeEthForMevEth{ value: amountIn }(address(this), amountIn, amountOutMin, block.timestamp);
        assertGt(shares, 0);
    }

    function testRedeemEth(uint80 amountIn) external {
        vm.assume(amountIn > 2 ether);
        vm.assume(amountIn < 10000 ether);
        // uint256 amountIn = 100 ether;
        vm.deal(address(this), amountIn);
        uint256 shares = router.stakeEthForMevEth{ value: amountIn }(address(this), amountIn, 1, block.timestamp);
        uint256 amountOutMin = 1;
        ERC20(address(MEVETH)).approve(address(router), shares);
        uint256 assets = router.redeemMevEthForEth(false, address(this), shares / 2, amountOutMin, block.timestamp);
        assertGt(assets, 0);
        assets = router.redeemMevEthForEth(true, address(this), shares / 2, amountOutMin, block.timestamp);
        assertGt(assets, 0);
    }
}
