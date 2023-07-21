// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

function deployBytecode(bytes memory bytecode) returns (address) {
    address addr;
    assembly {
        addr := create(0, add(bytecode, 0x20), mload(bytecode))
        if iszero(extcodesize(addr)) {
            revert(0, 0)
        }
    }
    return addr;
}
