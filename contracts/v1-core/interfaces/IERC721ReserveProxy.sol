// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IERC721ReserveProxy {
    event AdminChanged(address previousAdmin, address newAdmin);
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event BeaconUpgraded(address indexed beacon);
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );
    event EIP712DomainChanged();
    event Initialized(uint8 version);
    event MetadataUpdate(uint256 _tokenId);
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Upgraded(address indexed implementation);

    function CLOCK_MODE() external view returns (string memory);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function MULTI_TOKEN_RESERVE() external view returns (address);

    function UPGRADER_ROLE() external view returns (bytes32);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function clock() external view returns (uint48);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function delegates(address account) external view returns (address);

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    function getApproved(uint256 tokenId) external view returns (address);

    function getPastTotalSupply(uint256 timepoint)
        external
        view
        returns (uint256);

    function getPastVotes(address account, uint256 timepoint)
        external
        view
        returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVotes(address account) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(
        address _contractAdmin,
        address _multiTokenReserve,
        uint256 _reserveCollectionId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function mint(address _to, uint256 _tokenId) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function ownerOf(uint256 _nftId) external view returns (address);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;
}
