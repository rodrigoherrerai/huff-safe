// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

contract SingletonTest is Base_Test {
    function testThreshold() public {
        assertEq(singleton.getThreshold(), 1);
    }

    function testNonce() public {
        assertEq(singleton.nonce(), 0);
    }

    function testOwners() public {
        assertEq(singleton.ownerCount(), 0);
    }

    function testSetupShouldRevert() public {
        address[] memory owners = new address[](2);
        owners[0] = address(0xaaa);
        owners[1] = address(0xbbb);

        vm.expectRevert();
        singleton.setup(
            owners, 1, address(0), new bytes(0), address(0), address(0), 0, payable(address(0))
        );
    }
}
