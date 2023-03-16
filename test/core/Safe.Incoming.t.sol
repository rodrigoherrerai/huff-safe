// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

contract TransferHelper {
    function transferEth(address safe) public payable returns (bool success) {
        payable(safe).transfer(msg.value);
    }

    function sendEth(address safe) public payable returns (bool success) {
        require(payable(safe).send(msg.value));
    }

    function callEth(address safe) public payable returns (bool success) {
        (success,) = safe.call{value: msg.value}("");
        require(success);
    }
}

contract NativeCurrencyPaymentFallbackTest is Base_Test {
    TransferHelper public transferHelper;

    function setUp() public {
        transferHelper = new TransferHelper();
    }

    function testReceiveEthViaTransfer() public {
        assertEq(address(safe).balance, 0);

        vm.expectRevert();
        // Notes: It is not possible to load storage + a call + emit event with 2300 gas.
        transferHelper.sendEth{value: 1 ether}(address(safe));

        assertEq(address(safe).balance, 0);
    }

    function testReceiveEthViaSend() public {
        assertEq(address(safe).balance, 0);

        vm.expectRevert();
        transferHelper.transferEth{value: 1 ether}(address(safe));

        assertEq(address(safe).balance, 0);
    }

    function testReceiveEthViaCall() public {
        assertEq(address(safe).balance, 0);

        transferHelper.callEth{value: 1 ether}(address(safe));
        // @todo check that the events emit correctly.
        assertEq(address(safe).balance, 1 ether);
    }
}
