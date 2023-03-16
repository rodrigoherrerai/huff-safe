// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum, MockSafe} from "../shared/MockSafe.sol";

contract FuzzCore is Base_Test {
    function testFuzzSingletonSetup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) public {
        // It shouldn't be possible to set it up after initialization.
        vm.expectRevert();
        singleton.setup(
            _owners, _threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver
        );
    }

    function testFuzzSafeSetup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) public {
        // It shouldn't be possible to set it up after initialization.
        vm.expectRevert();
        safe.setup(
            _owners, _threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver
        );
    }

    function testFuzzAuthorization__addOwnerWithThreshold(address owner, uint256 _threshold)
        public
    {
        vm.expectRevert();
        singleton.addOwnerWithThreshold(owner, _threshold);

        vm.expectRevert();
        safe.addOwnerWithThreshold(owner, _threshold);
    }

    function testFuzzAuthorization__changeThreshold(uint256 _threshold) public {
        vm.expectRevert();
        singleton.changeThreshold(_threshold);

        vm.expectRevert();
        safe.changeThreshold(_threshold);
    }

    function testFuzzAuthorization__removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public {
        vm.expectRevert();
        singleton.removeOwner(prevOwner, owner, _threshold);

        vm.expectRevert();
        safe.removeOwner(prevOwner, owner, _threshold);
    }

    function testFuzzAuthorization__enableModule(address module) public {
        vm.expectRevert();
        safe.enableModule(module);
    }

    function testFuzzSingletonExecTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        bool callOrDelegate,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public {
        Enum.Operation operation;

        if (callOrDelegate) {
            operation = Enum.Operation.Call;
        } else {
            operation = Enum.Operation.DelegateCall;
        }

        vm.expectRevert();
        singleton.execTransaction(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signatures
        );
    }

    function testFuzzSafeExecTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        bool callOrDelegate,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public {
        Enum.Operation operation;

        if (callOrDelegate) {
            operation = Enum.Operation.Call;
        } else {
            operation = Enum.Operation.DelegateCall;
        }

        vm.expectRevert();
        singleton.execTransaction(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signatures
        );
    }
}
