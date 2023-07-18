// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./MultiTokenReserveV1.sol";
import "./getTokenProtocolData.sol";

contract ERC721ReserveProxy is
    Initializable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721VotesUpgradeable,
    UUPSUpgradeable
{
    MultiTokenReserveV1 public MULTI_TOKEN_RESERVE;
    uint256 private RESERVE_COLLECTION_ID;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _contractAdmin,
        address _multiTokenReserve,
        uint256 _reserveCollectionId
    ) public initializer {
        MULTI_TOKEN_RESERVE = MultiTokenReserveV1(_multiTokenReserve);
        RESERVE_COLLECTION_ID = _reserveCollectionId;

        __UUPSUpgradeable_init();
        __ERC721_init(name(), symbol());
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __ERC721Votes_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _contractAdmin);
        _grantRole(MINTER_ROLE, _contractAdmin);
        _grantRole(UPGRADER_ROLE, _contractAdmin);
    }

    function balanceOf(
        address _owner
    )
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (uint256)
    {
        return
            MULTI_TOKEN_RESERVE
                .getOwnerNfts(RESERVE_COLLECTION_ID, _owner)
                .length;
    }

    function ownerOf(
        uint256 _nftId
    )
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (address)
    {
        uint256 tokenId = MULTI_TOKEN_RESERVE.getIndexNft(
            RESERVE_COLLECTION_ID,
            _nftId
        );
        (, , , , , , , address owner, ) = getTokenProtocolData(
            address(MULTI_TOKEN_RESERVE),
            tokenId
        );
        return owner;
    }

    function mint(
        address _to,
        uint256 _tokenId
    ) public {
        MULTI_TOKEN_RESERVE.mint(
            _to,
            _tokenId,
            RESERVE_COLLECTION_ID,
            1,
            ""
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable, IERC721Upgradeable) {
        MULTI_TOKEN_RESERVE.safeTransferFrom(_from, _to, _tokenId, 1, data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) {
        MULTI_TOKEN_RESERVE.safeTransferFrom(_from, _to, _tokenId, 1, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) {
        MULTI_TOKEN_RESERVE.safeTransferFrom(_from, _to, _tokenId, 1, "");
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return MULTI_TOKEN_RESERVE.uri(_tokenId, RESERVE_COLLECTION_ID);
    }

    function totalSupply()
        public
        view
        override(ERC721EnumerableUpgradeable)
        returns (uint256)
    {
        (uint256 _totalSupply, , , , , ) = MULTI_TOKEN_RESERVE.NFT_COLLECTIONS(
            RESERVE_COLLECTION_ID
        );
        return _totalSupply;
    }

    function tokenByIndex(
        uint256 _index
    ) public view override(ERC721EnumerableUpgradeable) returns (uint256) {
        require(
            _index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _index;
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) public view override(ERC721EnumerableUpgradeable) returns (uint256) {
        require(
            _index < balanceOf(_owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return
            MULTI_TOKEN_RESERVE.getOwnerNfts(RESERVE_COLLECTION_ID, _owner)[
                _index
            ];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC721URIStorageUpgradeable,
            ERC721Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
