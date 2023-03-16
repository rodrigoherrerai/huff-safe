// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum, MockSafe} from "../shared/MockSafe.sol";

contract Setter {
    uint256 public x;

    function increment() public {
        x++;
    }
}

contract Upgrader {
    address public singleton;

    function upgradeSingleton(address _singleton) public {
        singleton = _singleton;
    }
}

contract NewSingleton {
    function yes() public pure returns (string memory) {
        return "yes";
    }
}

contract SafeCoreTest is Base_Test {
    function testSendEth() public {
        assertEq(address(safe).balance, 0);
        _fundSafe(1 ether);

        address to = address(0xff);
        assertEq(to.balance, 0);

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

        bool success = safe.execTransaction(
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
        );
        assertTrue(success);

        // eth should be sent
        assertEq(to.balance, value);
        assertEq(address(safe).balance, 1 ether - 0.1 ether);
    }

    function testSendPayload() public {
        Setter setter = new Setter();
        assertEq(setter.x(), 0);

        address to = address(setter);
        // bytes4(keccak256("increment()"))
        bytes memory data = hex"d09de08a";

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        // x should be incremented.
        assertEq(setter.x(), 1);
    }

    /// Upgrades the singleton.
    function testDelegateCall() public {
        Upgrader upgrader = new Upgrader();
        NewSingleton newSingleton = new NewSingleton();

        address to = address(upgrader);
        bytes memory data =
            abi.encodeWithSignature("upgradeSingleton(address)", address(newSingleton));

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.DelegateCall, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        (bool _success, bytes memory result) = address(safe).call(abi.encodeWithSignature("yes()"));
        assertTrue(_success);

        // Should have a new singleton.
        (string memory _result) = abi.decode(result, (string));
        assertEq(keccak256(abi.encode(_result)), keccak256(abi.encode("yes")));
    }

    function testInvalidSigner() public {
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(5, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        vm.expectRevert();
        bool success = safe.execTransaction(
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
        );
    }

    function testInvalidSignatureLength() public {
        _fundSafe(1 ether);

        address to = address(0xff);
        assertEq(to.balance, 0);

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
        (r);
        bytes memory sigs = abi.encodePacked(v, s);

        vm.expectRevert();
        bool success = safe.execTransaction(
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
        );
        (success);
    }

    function testSignaturesBelowThreshold() public {
        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        // Let's change it to 2.
        _changeThreshold(2);
        assertEq(safe.getThreshold(), 2);

        address to = address(0xbb);
        bytes32 txHash = safe.getTransactionHash(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);

        vm.expectRevert();
        bool success = safe.execTransaction(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        (success);
    }

    function testDuplicateSigner() public {
        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        // Let's change it to 2.
        _changeThreshold(2);
        assertEq(safe.getThreshold(), 2);

        address to = address(0xbb);
        bytes32 txHash = safe.getTransactionHash(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v, r, s, v);

        vm.expectRevert();
        bool success = safe.execTransaction(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        (success);
    }

    function testIncorrectOwnersOrder() public {
        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        // Let's change it to 2.
        _changeThreshold(2);
        assertEq(safe.getThreshold(), 2);

        address to = address(0xbb);
        bytes32 txHash = safe.getTransactionHash(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );

        // owner 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory ownerOneSig = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(2, txHash);
        bytes memory ownerTwoSig = abi.encodePacked(r, s, v);

        assertTrue(vm.addr(1) > vm.addr(2));

        bytes memory sigs = abi.encodePacked(ownerOneSig, ownerTwoSig);

        vm.expectRevert();
        bool success = safe.execTransaction(
            to, 0, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        (success);
    }

    function testCorrectExecution__Threshold__2() public {
        _fundSafe(1 ether);

        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        // Let's change it to 2.
        _changeThreshold(2);
        assertEq(safe.getThreshold(), 2);

        // Initial balance is 0.
        address to = address(0xbb);
        assertEq(to.balance, 0);

        uint256 value = 1 ether;

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

        // owner 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory ownerOneSig = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(2, txHash);
        bytes memory ownerTwoSig = abi.encodePacked(r, s, v);

        assertTrue(vm.addr(1) > vm.addr(2));

        bytes memory sigs = abi.encodePacked(ownerTwoSig, ownerOneSig);

        bool success = safe.execTransaction(
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
        );
        assertTrue(success);

        // tx succeeded
        assertEq(to.balance, value);
    }

    function testCorrectExecution__Threshold__3() public {
        _fundSafe(1 ether);

        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        address newOwner = vm.addr(3);
        _addOwner(newOwner);
        assertTrue(safe.isOwner(newOwner));
        assertEq(safe.ownerCount(), 3);

        // Let's change it to 3.
        _changeThreshold(3);
        assertEq(safe.getThreshold(), 3);

        // Initial balance is 0.
        address to = address(0xbb);
        assertEq(to.balance, 0);

        uint256 value = 1 ether;

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

        // owner 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory ownerOneSig = abi.encodePacked(r, s, v);

        // owner 2
        (v, r, s) = vm.sign(2, txHash);
        bytes memory ownerTwoSig = abi.encodePacked(r, s, v);

        // owner 3
        (v, r, s) = vm.sign(3, txHash);
        bytes memory ownerThreeSig = abi.encodePacked(r, s, v);

        assertTrue(vm.addr(1) > vm.addr(2) && vm.addr(3) < vm.addr(1) && vm.addr(3) > vm.addr(2));

        bytes memory sigs = abi.encodePacked(ownerTwoSig, ownerThreeSig, ownerOneSig);

        bool success = safe.execTransaction(
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
        );
        assertTrue(success);

        //tx succeeded
        assertEq(to.balance, value);
    }

    function testDuplicateSig() public {
        _fundSafe(1 ether);

        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        address newOwner = vm.addr(3);
        _addOwner(newOwner);
        assertTrue(safe.isOwner(newOwner));
        assertEq(safe.ownerCount(), 3);

        // Let's change it to 3.
        _changeThreshold(3);
        assertEq(safe.getThreshold(), 3);

        address to = address(0xbb);
        uint256 value = 1 ether;

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

        // owner 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory ownerOneSig = abi.encodePacked(r, s, v);

        // owner 2
        (v, r, s) = vm.sign(2, txHash);
        bytes memory ownerTwoSig = abi.encodePacked(r, s, v);

        // duplicate sigs.
        bytes memory sigs = abi.encodePacked(ownerTwoSig, ownerTwoSig, ownerOneSig);

        vm.expectRevert();
        bool success = safe.execTransaction(
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
        );
        (success);
    }

    function testUsedNonce() public {
        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        bytes32 txHash = safe.getTransactionHash(
            address(0),
            0,
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
        bytes memory sig = abi.encodePacked(r, s, v);

        bool success = safe.execTransaction(
            address(0),
            0,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sig
        );
        assertTrue(success);

        // nonce should be 1.
        assertEq(safe.nonce(), 1);

        // using sigs with old nonce.
        vm.expectRevert();
        success = safe.execTransaction(
            address(0),
            0,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sig
        );
    }

    function testInvalidNonce() public {
        // Current threshold is 1.
        assertEq(safe.getThreshold(), 1);

        bytes32 txHash = safe.getTransactionHash(
            address(0),
            0,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            safe.nonce() + 1 // nop
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectRevert();
        bool success = safe.execTransaction(
            address(0),
            0,
            new bytes(0),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sig
        );
        (success);
    }
}
