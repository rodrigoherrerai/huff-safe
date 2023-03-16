// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "foundry-huff/HuffDeployer.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum, MockSafe} from "../shared/MockSafe.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

contract NewModule {
    function sendEth(address safe, uint256 value, address to) external {
        bytes memory payload = abi.encodeWithSignature(
            "execTransactionFromModule(address,uint256,bytes,uint8)", to, value, new bytes(0), 0
        );

        (bool success,) = safe.call(payload);
        require(success);
    }
}

contract OwnerManagerTest is Base_Test {
    function testEnableModuleAuthorized() public {
        address newModule = address(0xbaba);
        vm.expectRevert();
        safe.enableModule(newModule);
    }

    function testEnableModule() public {
        address to = address(safe);
        address newModule = address(0xbaba);

        // New module shouldn't be enabled.
        assertFalse(safe.isModuleEnabled(newModule));

        bytes memory data = abi.encodeWithSignature("enableModule(address)", newModule);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        assertTrue(success);

        // Should be enabled.
        assertTrue(safe.isModuleEnabled(newModule));
    }

    function testDisableModuleAuthorized() public {
        address module = address(0xffff);
        _addModule(module);
        assertTrue(safe.isModuleEnabled(module));

        address prevModule = address(0x1);
        vm.expectRevert();
        safe.disableModule(prevModule, module);
    }

    function testDisableModule() public {
        //// First we add the module
        address module = address(0xbaba);

        assertFalse(safe.isModuleEnabled(module));

        _addModule(module);
        assertTrue(safe.isModuleEnabled(module));
        ////

        address prevModule = address(0x1);
        bytes memory data =
            abi.encodeWithSignature("disableModule(address,address)", prevModule, module);

        bytes32 txHash = safe.getTransactionHash(
            address(safe),
            0,
            data,
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
            address(safe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        );
        assertTrue(success);

        // should be disabled
        assertFalse(safe.isModuleEnabled(module));
    }

    function testSendEthFromModule() public {
        NewModule newModule = new NewModule();
        _addModule(address(newModule));
        assertTrue(safe.isModuleEnabled(address(newModule)));

        _fundSafe(1 ether);
        assertEq(address(safe).balance, 1 ether);

        address to = address(0xffff);
        newModule.sendEth(address(safe), 1 ether, to);

        assertEq(address(safe).balance, 0);
        assertEq(to.balance, 1 ether);
    }

    function testUnauthorizedModule() public {
        NewModule module = new NewModule();
        assertFalse(safe.isModuleEnabled(address(module)));

        _fundSafe(1 ether);
        assertEq(address(safe).balance, 1 ether);

        address to = address(0xffff);

        vm.expectRevert();
        module.sendEth(address(safe), 1 ether, to);

        assertEq(address(safe).balance, 1 ether);
        assertEq(to.balance, 0);
    }
}
