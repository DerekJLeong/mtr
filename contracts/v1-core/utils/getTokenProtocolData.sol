// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

// Define magic numbers as constants
// uint256 constant DATA_SIZE = 8 * 0x20; // Size of data for 8 uint256
// bytes4 constant FUNC_SIG = bytes4(keccak256("TOKEN_RESERVE(uint256)")); // Function signature hash

// // Function to get tuple data from a multi token reserve
// function getTupleData(
//     address multiTokenReserve,
//     uint256 _tokenId
// ) view returns (bytes memory) {
//     // Encode function signature and parameters
//     bytes memory encodedData = abi.encodeWithSelector(FUNC_SIG, _tokenId);

//     // Call the multi token reserve contract
//     (bool success, bytes memory result) = multiTokenReserve.staticcall(encodedData);

//     // Revert if the call failed
//     require(success, "Failed to call TOKEN_RESERVE function on multi token reserve contract");

//     return result;
// }

// // Function to get protocol data for a token
// function getTokenProtocolData(
//     address multiTokenReserve,
//     uint256 _tokenId
// )
//     view
//     returns (
//         uint256 totalSupply,
//         uint256 maxSupply,
//         uint8 granularity,
//         string memory name,
//         string memory symbol,
//         string memory uri,
//         address owner,
//         address creator
//     )
// {
//     // Get the tuple data
//     bytes memory tupleData = getTupleData(multiTokenReserve, _tokenId);

//     // Decode the tuple data
//     (
//         totalSupply,
//         maxSupply,
//         granularity,
//         name,
//         symbol,
//         uri,
//         owner,
//         creator
//     ) = abi.decode(tupleData, (uint256, uint256, uint8, string, string, string, address, address));

//         // Return the protocol data
//     return (
//         totalSupply,
//         maxSupply,
//         granularity,
//         name,
//         symbol,
//         uri,
//         owner,
//         creator
//     );
// }

// -----------------

// Define magic numbers as constants
uint256 constant PTR = 0x40; // Memory pointer
uint256 constant DATA_SIZE = 8 * 0x20; // Size of data for 8 uint256
uint256 constant OFFSET = 0x20; // Offset for length field in dynamic types
uint256 constant SHIFT = 0x20; // Shift for length field in dynamic types
bytes4 constant FUNC_SIG = bytes4(keccak256("TOKEN_RESERVE(uint256)")); // Function signature hash

// Function to get tuple data from a multi token reserve
function getTupleData(
    address multiTokenReserve,
    uint256 _tokenId
) view returns (uint256[8] memory) {
    // Encode function signature and parameters
    bytes memory encodedData = abi.encode(FUNC_SIG, _tokenId);
    uint256[8] memory tupleData;
    bool success;

    assembly {
        // Call the multi token reserve contract
        let ptr := mload(PTR)
        success := staticcall(
            gas(),
            multiTokenReserve,
            add(encodedData, 32),
            mload(encodedData),
            ptr,
            DATA_SIZE
        )
        // Load the returned data
        tupleData := ptr
    }

    // Revert if the call failed
    require(success, "Failed to call multi token reserve contract");

    return tupleData;
}

// Function to get protocol data for a token
function getTokenProtocolData(
    address multiTokenReserve,
    uint256 _tokenId
)
    view
    returns (
        uint256 totalSupply,
        uint256 maxSupply,
        uint8 granularity,
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        address creator
    )
{
    // Check that the multi token reserve address is not zero
    require(
        multiTokenReserve != address(0),
        "MultiTokenReserve address cannot be 0"
    );
    // Get the tuple data
    uint256[8] memory tupleData = getTupleData(multiTokenReserve, _tokenId);

    // Return the protocol data
    return (
        tupleData[0], // totalSupply
        tupleData[1], // maxSupply
        uint8(tupleData[2]), // granularity
        string(abi.encodePacked(tupleData[3])),
        string(abi.encodePacked(tupleData[4])),
        string(abi.encodePacked(tupleData[5])),
        address(uint160(tupleData[6])), // owner
        address(uint160(tupleData[7])) // creator
    );
}