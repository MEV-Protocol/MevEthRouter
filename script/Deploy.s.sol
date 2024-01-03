// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MevEthRouter.sol";

contract DeployScript is Script {
    function run() public {
        address authority = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;
        vm.startBroadcast();
        new MevEthRouter(authority);
        vm.stopBroadcast();
    }
}
