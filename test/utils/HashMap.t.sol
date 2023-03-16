// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "foundry-huff/HuffDeployer.sol";

contract HashMapTest is Test {
    HashMapInterface public hashMap;
    uint256 public SLOT = 2;

    function setUp() public {
        address addr = HuffDeployer.deploy("test/HashMapTest");
        hashMap = HashMapInterface(addr);
    }

    function testSetterAndGetter() public {
        address key = address(0x1);
        address value = address(0x1234);

        hashMap.set(key, value, SLOT);

        assertEq(hashMap.get(key, SLOT), value);
    }
}

interface HashMapInterface {
    function get(address key, uint256 slot) external view returns (address);
    function set(address key, address value, uint256 slot) external;
}
