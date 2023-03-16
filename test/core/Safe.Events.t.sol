// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum} from "../shared/MockSafe.sol";

contract SafeCoreTest is Base_Test {
    event ExecutionSuccess(bytes32 txHash, uint256 payment);
    event ExecutionFailure(bytes32 txHash, uint256 payment);

    function testEvent__ExecutionSuccess() public {
        assertEq(address(safe).balance, 0);
        _fundSafe(1 ether);

        address to = address(0xff);
        uint256 value = 0.1 ether;
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, false, false);
        emit ExecutionSuccess(txHash, 0);
        assertTrue(safe.execTransaction(
            to,
            value,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ));
    }

    function testEvent__ExecutionFailure() public {
        assertEq(address(safe).balance, 0);
        _fundSafe(1 ether);

        address to = address(0xff);

        uint256 value = 100 ether;
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, false, false);
        emit ExecutionFailure(txHash, 0);
        assertFalse(safe.execTransaction(
            to,
            value,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ));
    }

}
