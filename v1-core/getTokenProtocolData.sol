// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.18;

function getTokenProtocolData(address multiTokenReserve, uint256 _tokenId)
        view
        returns (
            uint256,
            uint256,
            uint8,
            string memory,
            string memory,
            string memory,
            bool,
            address,
            address
        )
    {
        bytes memory encodedData = abi.encodeWithSignature(
            "TOKEN_RESERVE(uint256)",
            _tokenId
        );
        string memory tokenName;
        string memory tokenSymbol;
        string memory tokenUri;
        uint256[9] memory tupleData;

        assembly {
            let ptr := mload(0x40)
            let success := staticcall(
                gas(),
                multiTokenReserve,
                add(encodedData, 0x20),
                mload(encodedData),
                ptr,
                0x180
            )
            if iszero(success) {
                revert(0, 0)
            }
            tupleData := mload(ptr)
            // Get the length of the string data
            let nameLen := shr(0x60, shl(0x60, mload(add(tupleData, 0x80))))
            let symbolLen := shr(0x60, shl(0x60, mload(add(tupleData, 0xA0))))
            let uriLen := shr(0x60, shl(0x60, mload(add(tupleData, 0xC0))))

            // Calculate the memory required for string data
            let nameSize := add(nameLen, 0x20)
            let symbolSize := add(symbolLen, 0x20)
            let uriSize := add(uriLen, 0x20)

            // Allocate memory for string data
            tokenName := mload(0x40)
            tokenSymbol := add(tokenName, nameSize)
            tokenUri := add(tokenSymbol, symbolSize)

            // Store the length of each string
            mstore(tokenName, nameLen)
            mstore(tokenSymbol, symbolLen)
            mstore(tokenUri, uriLen)

            // Copy the string data
            // Name
            calldatacopy(
                add(tokenName, 0x20),
                add(0x80, shl(0x60, add(tupleData, 0xA0))),
                nameLen
            )
            // Symbol
            calldatacopy(
                add(tokenSymbol, 0x20),
                add(0x80, shl(0x60, add(tupleData, 0xC0))),
                symbolLen
            )
            // URI
            calldatacopy(
                add(tokenUri, 0x20),
                add(0x80, shl(0x60, add(tupleData, 0xE0))),
                uriLen
            )
        }

        return (
            tupleData[0],
            tupleData[1],
            uint8(tupleData[2]),
            tokenName,
            tokenSymbol,
            tokenUri,
            tupleData[6] != 0,
            address(uint160(tupleData[7])),
            address(uint160(tupleData[8]))
        );
    }