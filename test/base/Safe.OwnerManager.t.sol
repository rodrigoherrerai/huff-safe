// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum, MockSafe} from "../shared/MockSafe.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

contract OwnerManagerTest is Base_Test {
    function testSetupShouldRevert() public {
        address[] memory owners = new address[](2);
        owners[0] = address(0xaaa);
        owners[1] = address(0xbbb);

        vm.expectRevert();
        safe.setup(
            owners, 1, address(0), new bytes(0), address(0), address(0), 0, payable(address(0))
        );
    }

    function testAddOwnerWithThresholdAuthorized() public {
        vm.expectRevert();
        safe.addOwnerWithThreshold(address(0xff), 1);
    }

    function testRemoveOwnerAuthorized() public {
        address owner_2 = vm.addr(2);
        assertTrue(safe.isOwner(owner_2));
        vm.expectRevert();
        safe.removeOwner(vm.addr(1), owner_2, 1);
    }

    function testChangeThresholdAuthorized() public {
        vm.expectRevert();
        safe.changeThreshold(1);
    }

    function testGetOwners() public {
        address[] memory owners = safe.getOwners();
        assertEq(owners[0], vm.addr(1));
        assertEq(owners[1], vm.addr(2));
    }

    function testIsOwner() public {
        assertTrue(safe.isOwner(vm.addr(1)));
        assertTrue(safe.isOwner(vm.addr(2)));
        assertFalse(safe.isOwner(address(0xff)));
        assertFalse(safe.isOwner(address(0xaaa)));
    }

    function testOwnerCount() public {
        assertEq(safe.ownerCount(), 2);
    }

    function testGetThreshold() public {
        assertEq(safe.getThreshold(), threshold);
    }

    function testAddOwnerWithThreshold() public {
        address to = address(safe);
        address newOwner = address(0xbaba);

        // Not an owner.
        assertFalse(safe.isOwner(newOwner));

        // Owner count should be 2.
        assertEq(safe.ownerCount(), 2);

        bytes memory data =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        // new owner should be set.
        assertTrue(safe.isOwner(newOwner));
        assertEq(safe.getThreshold(), threshold);

        // Owner count should be 3.
        assertEq(safe.ownerCount(), 3);
    }

    function testAddOwnerWithThresholdInvalidOwner__zero() public {
        address to = address(safe);
        address newOwner = address(0x0);

        bytes memory data =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
        assertFalse(safe.isOwner(newOwner));
    }

    function testAddOwnerWithThresholdInvalidOwner__sentinel() public {
        address to = address(safe);
        address newOwner = address(0x1);

        bytes memory data =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
        assertFalse(safe.isOwner(newOwner));
    }

    function testAddOwnerWithThresholdInvalidOwner__this() public {
        address to = address(safe);
        address newOwner = address(address(safe));

        bytes memory data =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
        assertFalse(safe.isOwner(newOwner));
    }

    function testAddOwnerWithThresholdInvalidOwner__currentOwner() public {
        address to = address(safe);
        address newOwner = vm.addr(1);

        bytes memory data =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
    }

    function testRemoveOwner() public {
        address to = address(safe);
        address prevOwner = vm.addr(1);
        address owner = vm.addr(2);
        assertTrue(safe.isOwner(prevOwner));
        assertTrue(safe.isOwner(owner));

        // Owner count should be 2.
        assertEq(safe.ownerCount(), 2);

        bytes memory data = abi.encodeWithSignature(
            "removeOwner(address,address,uint256)", prevOwner, owner, threshold
        );

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        // Owner should be removed.
        assertFalse(safe.isOwner(owner));

        assertTrue(safe.isOwner(prevOwner));
        assertEq(safe.getThreshold(), threshold);

        // Owner count should be 1.
        assertEq(safe.ownerCount(), 1);
    }

    function testChangeThreshold() public {
        address to = address(safe);

        uint256 newThreshold = 2;
        assertEq(safe.getThreshold(), 1);

        bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        // Threshold changed.
        assertEq(safe.getThreshold(), newThreshold);
    }

    function testChangeThresholdInvalidThreshold__zero() public {
        address to = address(safe);
        uint256 newThreshold = 0;

        bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
        assertEq(safe.getThreshold(), threshold);
    }

    function testChangeThresholdInvalidThreshold__big() public {
        address to = address(safe);
        uint256 newThreshold = 10;
        bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertFalse(success);
        assertEq(safe.getThreshold(), threshold);
    }
}
