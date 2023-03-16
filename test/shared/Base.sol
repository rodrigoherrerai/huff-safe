// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "foundry-huff/HuffDeployer.sol";

import {Enum} from "../shared/MockSafe.sol";
import {ProxyFactoryInterface} from "../interfaces/ProxyFactoryInterface.sol";
import {SingletonInterface} from "../interfaces/SingletonInterface.sol";

/// @notice Base contract with shared logic across test contracts.
abstract contract Base_Test is Test {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    bytes32 public constant SAFE_TX_TYPEHASH =
        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;
    bytes32 constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    /*//////////////////////////////////////////////////////////////
                            SHARED CONTRACTS
    //////////////////////////////////////////////////////////////*/
    ProxyFactoryInterface public proxyFactory;
    SingletonInterface public singleton;
    SingletonInterface public safe;

    /*//////////////////////////////////////////////////////////////
                             INITIAL STATE
    //////////////////////////////////////////////////////////////*/
    address[] public owners = new address[](2);
    uint256 public threshold;
    address public fallbackHandler;

    constructor() {
        // The proxy factory.
        address _proxyFactory = HuffDeployer.deploy("proxies/ProxyFactory");
        proxyFactory = ProxyFactoryInterface(_proxyFactory);

        // The singleton.
        address _singleton = HuffDeployer.deploy("Safe");
        singleton = SingletonInterface(_singleton);

        // The safe owners.
        owners[0] = address(vm.addr(1));
        owners[1] = address(vm.addr(2));

        // Set the initial threshold to 1.
        threshold = 1;

        // Fallback handler.
        fallbackHandler = address(0xbaba);

        // util
        address zero = address(0x0);

        // Deployment initializer.
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            threshold,
            zero,
            new bytes(0),
            fallbackHandler,
            zero,
            zero,
            payable(zero)
        );

        // Newly created safe with owners and threshold set.
        address _safe = proxyFactory.createProxyWithNonce(address(singleton), initializer, 0);
        safe = SingletonInterface(_safe);
    }

    function _changeThreshold(uint256 newThreshold) internal {
        address to = address(safe);
        bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        require(success);
    }

    function _fundSafe(uint256 value) internal {
        (bool success,) = address(safe).call{value: value}("");
        require(success);
    }

    function _addOwner(address newOwner) internal {
        address to = address(safe);
        bytes memory data = abi.encodeWithSignature(
            "addOwnerWithThreshold(address,uint256)", newOwner, safe.getThreshold()
        );

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        require(success);
    }

    function _createSafe(address[] memory _owners, uint256 _threshold, address fallbackHandler)
        internal
        returns (address newSafe)
    {
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _owners,
            _threshold,
            address(0),
            "0x",
            fallbackHandler,
            address(0),
            0,
            payable(address(0))
        );

        uint256 saltNonce = uint256(bytes32(keccak256(abi.encodePacked(_owners, _threshold))));
        newSafe = proxyFactory.createProxyWithNonce(address(singleton), initializer, saltNonce);
        require(newSafe != address(0));
    }

    function _addModule(address newModule) internal {
        address to = address(safe);
        bytes memory data = abi.encodeWithSignature("enableModule(address)", newModule);

        bytes32 txHash = safe.getTransactionHash(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), address(0), safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, txHash);
        bytes memory sigs = abi.encodePacked(r, s, v);
        bool success = safe.execTransaction(
            to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sigs
        );
        require(success);
    }
}
