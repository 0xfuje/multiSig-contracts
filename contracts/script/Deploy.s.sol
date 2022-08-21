// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { MultiSigFactory } from "../src/MultiSigFactory.sol";
import { MultiSig } from "../src/MultiSig.sol";

contract DeployMultiSig is Script {
    MultiSig ms;

    address[] owners;

    address alice = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address bob = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address chloe = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address daniel = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(chloe);
    }

    function run() public {
        vm.startBroadcast();
        ms = new MultiSig(owners, 2);
        vm.stopBroadcast();
    }
}

contract DeployMultiSigFactory is Script {
    MultiSigFactory msf;

    function run() public {
        vm.startBroadcast();
        msf = new MultiSigFactory();
        vm.stopBroadcast();
    }
}
