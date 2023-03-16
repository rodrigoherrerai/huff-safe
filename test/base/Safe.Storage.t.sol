// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {ProxyFactoryInterface} from "../interfaces/ProxyFactoryInterface.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

/// @notice Tests correct storage slots.
contract SafeStorageTest is Base_Test {
    function testStorage__0() public {
        // singleton
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(address(uint160(uint256(res))), address(singleton));
    }

    function testStorage__1() public {
        // modules
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(res, bytes32(0x0));
    }

    function testStorage__2() public {
        // owners
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000002;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(res, bytes32(0x0));
    }

    function testStorage__3() public {
        // owner count
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000003;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(res, bytes32(owners.length));
    }

    function testStorage__4() public {
        // threshold
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000004;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(res, bytes32(threshold));
    }

    function testStorage__5() public {
        // nonce
        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000005;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(res, bytes32(safe.nonce()));
    }

    function testStorage__fallbackHandler() public {
        // fallback handler
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        bytes32 res = vm.load(address(safe), slot);
        assertEq(address(uint160(uint256(res))), fallbackHandler);
    }
}
