// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

// Define magic numbers as constants
uint256 constant PTR = 0x40;
uint256 constant DATA_SIZE = 0x180;
uint256 constant OFFSET = 0x80;
uint256 constant SHIFT = 0x60;

// Function to get tuple data from a multi token reserve
function getTupleData(
    address multiTokenReserve,
    uint256 _tokenId
) view returns (uint256[9] memory) {
    // Encode function signature and parameters
    bytes memory encodedData = abi.encode(
        bytes4(keccak256("TOKEN_RESERVE(uint256)")),
        _tokenId
    );
    uint256[9] memory tupleData;

    assembly {
        // Call the multi token reserve contract
        let ptr := mload(PTR)
        let success := staticcall(
            gas(),
            multiTokenReserve,
            add(encodedData, 32),
            mload(encodedData),
            ptr,
            DATA_SIZE
        )
        // Revert if the call failed
        if iszero(success) {
            revert(0, 0)
        }
        // Load the returned data
        tupleData := ptr
    }

    return tupleData;
}

// Function to get string data from tuple data
function getStringData(
    uint256[9] memory tupleData
) pure returns (string memory, string memory, string memory) {
    string memory tokenName;
    string memory tokenSymbol;
    string memory tokenUri;

    assembly {
        // Get the length of the string data
        let nameLen := mload(add(tupleData, OFFSET))
        let symbolLen := mload(add(tupleData, add(OFFSET, 0x20)))
        let uriLen := mload(add(tupleData, add(OFFSET, 0x40)))

        // Copy the string data directly to the string variables
        let offset := add(tupleData, add(OFFSET, shl(SHIFT, add(OFFSET, 0x20))))
        calldatacopy(add(tokenName, 32), offset, nameLen)
        offset := add(tupleData, add(OFFSET, shl(SHIFT, add(OFFSET, 0x40))))
        calldatacopy(add(tokenSymbol, 32), offset, symbolLen)
        offset := add(tupleData, add(OFFSET, shl(SHIFT, add(OFFSET, 0x60))))
        calldatacopy(add(tokenUri, 32), offset, uriLen)
    }

    return (tokenName, tokenSymbol, tokenUri);
}

// Function to get protocol data for a token
function getTokenProtocolData(
    address multiTokenReserve,
    uint256 _tokenId
)
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
    // Check that the multi token reserve address is not zero
    require(multiTokenReserve != address(0), "MultiTokenReserve address cannot be 0");
    // Get the tuple data
    uint256[9] memory tupleData = getTupleData(multiTokenReserve, _tokenId);
    // Get the string data
    (
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenUri
    ) = getStringData(tupleData);

    // Return the protocol data
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
