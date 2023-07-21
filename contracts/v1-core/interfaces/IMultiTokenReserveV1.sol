// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IMultiTokenReserveV1 {
    event AdminChanged(address previousAdmin, address newAdmin);
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event BeaconUpgraded(address indexed beacon);
    event Initialized(uint8 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 indexed id);
    event Upgraded(address indexed implementation);

    function COIN_MINTER_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FUNGIBLE_TOKENS(uint256) external view returns (uint256);

    function NFT_COLLECTIONS(uint256)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 maxSupply,
            string memory name,
            string memory symbol,
            string memory baseUri,
            bool burnable
        );

    function NFT_COLLECTION_IDS() external view returns (uint256 _value);

    function NFT_MINTER_ROLE() external view returns (bytes32);

    function OPERATOR_ROLE() external view returns (bytes32);

    function TOKEN_COLLECTION(uint256) external view returns (uint256);

    function TOKEN_IDS() external view returns (uint256 _value);

    function TOKEN_RESERVE(uint256)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 maxSupply,
            uint8 granularity,
            string memory name,
            string memory symbol,
            string memory uri,
            bool burnable,
            address owner,
            address creator
        );

    function UPGRADER_ROLE() external view returns (bytes32);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function getIndexNft(uint256 cID, uint256 index)
        external
        view
        returns (uint256);

    function getOwnerNfts(uint256 cID, address account)
        external
        view
        returns (uint256[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize() external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function mint(
        address account,
        uint256 id,
        uint256 cID,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory cIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory newuri, uint256 cId) external;

    function setTokenUri(uint256 id, string memory newuri) external;

    function spawnCollection(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) external;

    function spawnToken(
        uint256 _maxSupply,
        uint8 _granularity,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;

    function uri(uint256 tokenId) external view returns (string memory);

    function uri(uint256 tokenId, uint256 cID)
        external
        view
        returns (string memory);
}
