// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { MultiSig } from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    event Submit(uint indexed txId);
    event ApproveFrom(address indexed sender, uint indexed txId);
    event RevokeFrom(address indexed sender, uint indexed txId);
    event Approve(uint indexed txId);
    event Revoke(uint indexed txId);
    event Execute(uint indexed txId);
    event DepositFrom(address indexed sender, uint value);

    enum Status {
        Submitted,
        Approved,
        Executed
    }

    struct Transaction {
        address to;
        uint value;
        bytes data;
        Status status;
    }

    address[] owners;
    MultiSig ms;

    address alice = address(0x83C85B50110062c7821AF2AC245DcCFB68F6dEB7);
    address bob = address(0x9907A0cF64Ec9Fbf6Ed8FD4971090DE88222a9aC);
    address chloe = address(0x71C7656EC7ab88b098defB751B7401B5f6d8976F);
    address daniel = address(0xD8A8d51441f5d3373060B84136F30DC2935EA28c);

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(chloe);
        ms = new MultiSig(owners, 2);
        hoax(address(ms), 10 ether);
    }

    function testDeposit() public {
        /* vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit DepositFrom(alice, 1 ether);
        payable(address(ms)).transfer(1 ether); */
    }

    function testInit() public {
        assertTrue(ms.isOwner(alice));
        assertTrue(ms.isOwner(bob));
        assertTrue(ms.isOwner(chloe));
        assertEq(ms.threshold(), 2);
    }

    function testSubmit() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit Submit(0);
        ms.submit(daniel, 1 ether, bytes('hi dan'));
        assertEq(ms.nextTxId(), 1);
        (,,, MultiSig.Status status) = ms.getTxInfo(0);
        assertEq(uint(status), 0);
    }

    function testApprove() public {
        vm.startPrank(alice);
        ms.submit(daniel, 1 ether, bytes('hi dan'));
        // setup end

        vm.expectEmit(true, true, false, false);
        emit ApproveFrom(alice, 0);
        ms.approve(0);
        vm.stopPrank();

        vm.expectEmit(true, false, false, false);
        emit ApproveFrom(bob, 0);
        vm.prank(bob);
        vm.expectEmit(true, false, false, false);
        emit Approve(0);
        ms.approve(0);
        (,,, MultiSig.Status status) = ms.getTxInfo(0);
        assertEq(uint(status), 1);

        assertTrue(ms.txApprovalVote(0, alice));
        assertTrue(ms.txApprovalVote(0, bob));
        assertFalse(ms.txApprovalVote(0, chloe));
    }

    function approvedSetup() internal {
        vm.startPrank(alice);
        ms.submit(daniel, 1 ether, bytes('hi dan'));
        ms.approve(0);
        vm.stopPrank();
        vm.prank(bob);
        ms.approve(0);
    }

    function testRevoke() public {
        approvedSetup();
        vm.startPrank(bob);
        vm.expectEmit(true, true, false, false);
        emit RevokeFrom(bob, 0);
        vm.expectEmit(true, false, false, false);
        emit Revoke(0);
        ms.revoke(0);
        (,,, MultiSig.Status status) = ms.getTxInfo(0);
        assertEq(uint(status), 0);
        assertFalse(ms.txApprovalVote(0, bob));
    }

    function testExecute() public {
        approvedSetup();
        vm.startPrank(bob);
        vm.expectEmit(true, false, false, false);
        emit Execute(0);
        ms.execute(0);
        (,,, MultiSig.Status status) = ms.getTxInfo(0);
        assertEq(uint(status), 2);

        assertEq(address(ms).balance, 9 ether);
        assertEq(daniel.balance, 1 ether);
    }
}
