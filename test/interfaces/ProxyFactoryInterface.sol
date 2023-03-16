// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface ProxyFactoryInterface {
    function getSalt(address, bytes memory initializer, uint256 saltNonce)
        external
        view
        returns (bytes32);
    function createProxyWithNonce(address singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address);
}
