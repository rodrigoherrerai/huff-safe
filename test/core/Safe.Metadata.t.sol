// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import {Enum, MockSafe} from "../shared/MockSafe.sol";
import {Base_Test} from "../shared/Base.sol";

contract MetadataTest is Base_Test {
    function testVersion() public {
        string memory version = safe.VERSION();
        assertEq(version, "1.4.0");
    }

    function testDomainSeparator() public {
        //     function domainSeparator() public view returns (bytes32) {
        //           return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
        //      }
        uint256 chainId = block.chainid;
        bytes32 target = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, address(safe)));
        assertEq(target, safe.domainSeparator());
    }

    function testDomainSeparatorTypeHash() public {
        bytes32 target = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
        assertEq(target, DOMAIN_SEPARATOR_TYPEHASH);
    }

    function testSafeTxTypeHash() public {
        bytes32 target = keccak256(
            "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
        );
        assertEq(target, SAFE_TX_TYPEHASH);
    }

    function testGetTransactionHash() public {
        MockSafe mockSafe = new MockSafe(address(safe));
        address to = address(0x1111);
        uint256 value = 12_313;
        bytes memory data =
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        Enum.Operation operation = Enum.Operation.Call;
        uint256 safeTxGas = 12_312_312_312;
        uint256 baseGas = 999_999_999;
        uint256 gasPrice = 9_999_999_999;
        address gasToken = address(0xaaaaaa);
        address refundReceiver = address(0xbbbbbbb);
        uint256 nonce = 1111;

        bytes32 mockTxHash = mockSafe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        bytes32 safeTxHash = safe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        assertEq(safeTxHash, mockTxHash);
    }

    function testEncodeTransactionData() public {
        MockSafe mockSafe = new MockSafe(address(safe));
        address to = address(0x1111);
        uint256 value = 12_313;
        bytes memory data = hex"ffffffffffffffffffffffff";
        Enum.Operation operation = Enum.Operation.Call;
        uint256 safeTxGas = 12_312_312_312;
        uint256 baseGas = 999_999_999;
        uint256 gasPrice = 9_999_999_999;
        address gasToken = address(0xaaaaaa);
        address refundReceiver = address(0xbbbbbbb);
        uint256 nonce = 1111;

        bytes memory mockEncodedData = mockSafe.encodeTransactionData(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        bytes memory encodedData = safe.encodeTransactionData(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        assertEq(encodedData, mockEncodedData);
    }
}
