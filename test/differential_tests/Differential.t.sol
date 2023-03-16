// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {Base_Test} from "../shared/Base.sol";
import {Enum, MockSafe} from "../shared/MockSafe.sol";

/// @notice Verifies correct implementation of core components of Safe.huff by testing it against Safe.sol.
contract DifferentialTest is Base_Test {
    MockSafe mockSafe;

    function setUp() public {
        mockSafe = new MockSafe(address(safe));
    }

    function testGetTransactionHash__differential(
        address to,
        uint256 value,
        bytes calldata data,
        bool callOrDelegate,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public {
        Enum.Operation operation;

        if (callOrDelegate) {
            operation = Enum.Operation.Call;
        } else {
            operation = Enum.Operation.DelegateCall;
        }

        bytes32 safeSolidityTxHash = mockSafe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            _nonce
        );

        bytes32 safeHuffTxHash = safe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            _nonce
        );
        assertEq(safeHuffTxHash, safeSolidityTxHash);
    }

    function testEncodeTransactionData__differential(
        address to,
        uint256 value,
        bytes calldata data,
        bool callOrDelegate,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public {
        Enum.Operation operation;

        if (callOrDelegate) {
            operation = Enum.Operation.Call;
        } else {
            operation = Enum.Operation.DelegateCall;
        }

        bytes memory safeSolidityTxData = mockSafe.encodeTransactionData(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            _nonce
        );

        bytes memory safeHuffTxData = safe.encodeTransactionData(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            _nonce
        );
        assertEq(safeHuffTxData, safeSolidityTxData);
    }
}
