// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {ProxyFactoryInterface} from "../interfaces/ProxyFactoryInterface.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

contract ProxyFactoryTest is Base_Test {
    function testInvalidSingletonAddress() public {
        vm.expectRevert();
        proxyFactory.createProxyWithNonce(address(0), new bytes(0), 0);
    }

    function testInvalidInitializer() public {
        vm.expectRevert();
        proxyFactory.createProxyWithNonce(address(singleton), "0x42baddad", 0);
    }

    function testCreateProxy() public {
        address[] memory owners = new address[](2);
        owners[0] = address(0x123);
        owners[1] = address(0x1234);

        uint256 threshold = 2;
        address fallbackHandler = address(0x1111);
        address newSafe = _createSafe(owners, threshold, fallbackHandler);
        SingletonInterface proxy = SingletonInterface(newSafe);

        assertEq(proxy.ownerCount(), 2);
        assertEq(proxy.getThreshold(), 2);

        address[] memory _owners = proxy.getOwners();

        for (uint256 i = 0; i < _owners.length; i++) {
            assertEq(_owners[i], owners[i]);
        }
    }

    function testSetupMultipleOwners() public {
        address[] memory owners = new address[](10);
        owners[0] = address(0xa);
        owners[1] = address(0xaa);
        owners[2] = address(0xaaa);
        owners[3] = address(0xaaaa);
        owners[4] = address(0xaaaaa);
        owners[5] = address(0xaaaaaa);
        owners[6] = address(0xaaaaaaa);
        owners[7] = address(0xaaaaaaaa);
        owners[8] = address(0xaaaaaaaaa);
        owners[9] = address(0xaaaaaaaaaa);

        uint256 threshold = 6;
        address fallbackHandler = address(0x1111);
        address newSafe = _createSafe(owners, threshold, fallbackHandler);
        SingletonInterface proxy = SingletonInterface(newSafe);

        assertEq(proxy.ownerCount(), 10);
        assertEq(proxy.getThreshold(), 6);

        address[] memory _owners = proxy.getOwners();

        for (uint256 i = 0; i < _owners.length; i++) {
            assertEq(_owners[i], owners[i]);
        }
    }

    function testCorrectFallbackHandler() public {
        address[] memory owners = new address[](10);
        owners[0] = address(0xa);
        address fallbackHandler = address(0x1111);
        address newSafe = _createSafe(owners, threshold, fallbackHandler);

        bytes32 res = vm.load(address(newSafe), FALLBACK_HANDLER_STORAGE_SLOT);
        assertEq(address(uint160(uint256(res))), fallbackHandler);
    }
}
