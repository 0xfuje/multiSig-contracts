// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { MultiSigFactory } from "../src/MultiSigFactory.sol";

contract MultiSigFactoryTest is Test {
    event Deploy(
        address indexed initiator,
        address contractAddress
    );

    MultiSigFactory msf;
    address[] owners;

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address chloe = vm.addr(3);
    
    function setUp() public {
        msf = new MultiSigFactory();

        owners.push(alice);
        owners.push(bob);
        owners.push(chloe);
    }

    function testDeploy() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deploy(alice, address(0x037FC82298142374d974839236D2e2dF6B5BdD8F));

        address wallet = msf.deploy(owners, 2);
        assertEq(msf.contracts(alice, 0), wallet);
    }

    function testFactoryInit() public {
        vm.prank(alice);
        address multiSig = msf.deploy(owners, 2);

        (, bytes memory data0) = multiSig
        .call(abi.encodeWithSignature("threshold()"));
        uint8 _threshold = abi.decode(data0, (uint8));
        assertEq(_threshold, 2);

        (, bytes memory data1) = multiSig
        .call(abi.encodeWithSignature("nextTxId()"));
        uint256 _nextTxId = abi.decode(data1, (uint256));
        assertEq(_nextTxId, 0); 
    }

    function testFactoryExecute() public {
        vm.startPrank(alice);
        address multiSig = msf.deploy(owners, 2);
        vm.deal(multiSig, 10 ether);

        (bool success0, ) = multiSig.call(abi.encodeWithSignature(
            "submit()",
            "0x6813eb9362372eef6200f3b1dbc3f819671cba69",
            1000000000000000000,
            "0x68692063686c6f65"
        ));
        assertTrue(success0);

        (bool success1, ) = multiSig.call(abi.encodeWithSignature(
            "approve()", 0
        ));
        assertTrue(success1);
        vm.stopPrank();

        vm.startPrank(bob);
        (bool success2, ) = multiSig.call(abi.encodeWithSignature(
            "approve()", 0
        ));
        assertTrue(success2);

        (bool success3, ) = multiSig.call(abi.encodeWithSignature(
            "execute()", 0
        ));
        assertTrue(success3);


        assertEq(chloe.balance, 1 ether);
    }
}