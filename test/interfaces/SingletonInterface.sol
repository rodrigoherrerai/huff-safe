// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import {Enum} from "../shared/MockSafe.sol";

interface SingletonInterface {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function changeThreshold(uint256) external;
    function disableModule(address, address) external;
    function domainSeparator() external view returns (bytes32);
    function enableModule(address) external;
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external returns (bool);
    function getChainId() external view returns (uint256);
    function getSingleton() external view returns (address);
    function getThreshold() external view returns (uint256);
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);
    function getOwners() external view returns (address[] memory);
    function isModuleEnabled(address module) external view returns (bool);
    function isOwner(address) external view returns (bool);
    function nonce() external view returns (uint256);
    function ownerCount() external view returns (uint256);
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
    function VERSION() external view returns (string memory);
}
