// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ERC20ReserveProxy.sol";
import "./ERC721ReserveProxy.sol";
// TODO: ERC777ReserveProxy.sol

contract MultiTokenReserveV1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC1155SupplyUpgradeable
{
    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter public TOKEN_IDS;
    CountersUpgradeable.Counter public NFT_COLLECTION_IDS;

    struct Token {
        // 1 - total supply of token
        uint256 totalSupply;
        // 2 - max supply of token
        uint256 maxSupply;
        // 3 - granularity of token (also known as "decimals")
        uint8 granularity;
        // 4 - name of token
        string name;
        // 5 - symbol of token
        string symbol;
        // 6 - URI of token metadata, if applicable
        string uri;
        // 7 - whether token is burnable
        bool burnable;
        // 8 - token owner
        address owner;
        // 9 - token creator
        address creator;
    }

    struct Collection {
        // 1 - total supply of NFTs
        uint256 totalSupply;
        // 2 - max supply of NFTs
        uint256 maxSupply;
        // 3 - name of NFT collection
        string name;
        // 4 - symbol of NFT collection
        string symbol;
        // 5 - URI of NFT metadata, if applicable
        string baseUri;
        // 6 - whether NFT is burnable
        bool burnable;
        // 7 - NFT Collection Index to Token ID
        mapping(uint256 => uint256) nfts; // index => tokenId
        // 8 - Address to Indexes[]
        mapping(address => uint256[]) owned; // owner => indexes
    }

    mapping(uint256 => Token) public TOKEN_RESERVE; // tokenId => Token
    mapping(uint256 => Collection) public NFT_COLLECTIONS; // cID => Collection
    mapping(uint256 => uint256) public TOKEN_COLLECTION; // tokenId => cID

    uint256[] public FUNGIBLE_TOKENS; // tokenIds of fungible tokens

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant COIN_MINTER_ROLE = keccak256("COIN_MINTER_ROLE");
    bytes32 public constant NFT_MINTER_ROLE = keccak256("NFT_MINTER_ROLE");

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC1155_init("https://www.test.ipfs.com/");
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155Receiver_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(COIN_MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        createFungibleToken(0, 18, "MyToken", "MT", "", true);
    }

    modifier verifyMint(
        address account,
        uint256 id,
        uint256 cID,
        uint256 amount,
        bytes memory data
    ) {
        mintData(account, id, cID, amount, data);
        _;
    }

    modifier verifyBatchMint(
        address account,
        uint256[] memory ids,
        uint256[] memory cIDs,
        uint256[] memory amounts,
        bytes memory data
    ) {
        require(
            ids.length == cIDs.length && ids.length == amounts.length,
            "Invalid input"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            mintData(account, ids[i], cIDs[i], amounts[i], data);
        }
        _;
    }

    function mintData(
        address account,
        uint256 id,
        uint256 cID,
        uint256 amount,
        bytes memory data
    ) internal {
        require(amount > 0, "Invalid amount");

        if (cID > 0 && cID < NFT_COLLECTION_IDS.current() && amount == 1) {
            require(
                hasRole(NFT_MINTER_ROLE, msg.sender),
                "Unauthorized NFT minter"
            );
            require(
                NFT_COLLECTIONS[cID].maxSupply == 0 ||
                    NFT_COLLECTIONS[cID].totalSupply + amount <=
                    NFT_COLLECTIONS[cID].maxSupply,
                "Cannot mint more than max supply"
            );

            createNonFungibleToken(
                string.concat(
                    NFT_COLLECTIONS[cID].name,
                    " ",
                    (NFT_COLLECTIONS[cID].totalSupply + 1).toString()
                ),
                NFT_COLLECTIONS[cID].symbol,
                data.length > 0 ? string(data) : ""
            );
            _mint(account, TOKEN_IDS.current(), amount, data);
        } else if (cID == 0 && TOKEN_RESERVE[id].granularity > 0) {
            require(
                hasRole(COIN_MINTER_ROLE, msg.sender),
                "Unauthorized coin minter"
            );
            require(
                TOKEN_RESERVE[id].maxSupply == 0 ||
                    TOKEN_RESERVE[id].totalSupply + amount <=
                    TOKEN_RESERVE[id].maxSupply,
                "Cannot mint more than max supply"
            );

            TOKEN_COLLECTION[id] = cID; // Tokens are in collection 0
            TOKEN_RESERVE[id].totalSupply += amount;
            _mint(account, id, amount, data);
        } else {
            revert("Invalid mint");
        }
    }

    function removeNFTId(address account, uint256 tokenId) internal {
        uint256 cID = TOKEN_COLLECTION[tokenId];
        int256 index = findNFTId(account, cID, tokenId);
        if (index == -1) {
            revert("Token ID not found");
        } else {
            NFT_COLLECTIONS[cID].owned[account][
                uint256(index)
            ] = NFT_COLLECTIONS[cID].owned[account][
                NFT_COLLECTIONS[cID].owned[account].length - 1
            ];
            NFT_COLLECTIONS[cID].owned[account].pop();
        }
    }

    function findNFTId(
        address account,
        uint256 collectionId,
        uint256 tokenId
    ) internal view returns (int256) {
        uint256[] memory ownedNfts = NFT_COLLECTIONS[collectionId].owned[
            account
        ];
        for (uint256 i = 0; i < ownedNfts.length; i++) {
            if (NFT_COLLECTIONS[collectionId].nfts[ownedNfts[i]] == tokenId) {
                return int256(i);
            }
        }
        return -1;
    }

    function addNFTData(address account, uint256 tokenId) internal {
        NFT_COLLECTIONS[TOKEN_COLLECTION[tokenId]].owned[account].push(tokenId);
        TOKEN_RESERVE[tokenId].owner = account;
    }

    function transferNFTData(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        addNFTData(to, tokenId);
        removeNFTId(from, tokenId);
    }

    function createToken(
        uint256 _maxSupply,
        uint8 _granularity,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) internal {
        TOKEN_RESERVE[TOKEN_IDS.current()] = Token({
            totalSupply: 0,
            maxSupply: _maxSupply,
            granularity: _granularity,
            name: _name,
            symbol: _symbol,
            uri: _tokenUri,
            burnable: _burnable,
            owner: address(0),
            creator: address(0)
        });
        TOKEN_IDS.increment();
    }

    function createFungibleToken(
        uint256 _maxSupply,
        uint8 _granularity,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) internal {
        FUNGIBLE_TOKENS.push(TOKEN_IDS.current());
        createToken(
            _maxSupply,
            _granularity,
            _name,
            _symbol,
            _tokenUri,
            _burnable
        );
    }

    function createNonFungibleToken(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri
    ) internal {
        NFT_COLLECTIONS[NFT_COLLECTION_IDS.current()].totalSupply++;
        createToken(1, 1, _name, _symbol, _tokenUri, true);
        addNFTData(msg.sender, TOKEN_IDS.current() - 1);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) internal {
        NFT_COLLECTION_IDS.increment();
        uint256 cID = NFT_COLLECTION_IDS.current();
        Collection storage newCollection = NFT_COLLECTIONS[cID];
        newCollection.totalSupply = 0;
        newCollection.maxSupply = 0;
        newCollection.name = _name;
        newCollection.symbol = _symbol;
        newCollection.baseUri = _tokenUri;
        newCollection.burnable = _burnable;
    }

    //
    // Public/External
    //
    function spawnToken(
        uint256 _maxSupply,
        uint8 _granularity,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        createFungibleToken(
            _maxSupply,
            _granularity,
            _name,
            _symbol,
            _tokenUri,
            _burnable
        );
        // Deploy ERC20 Proxy Conract
        address erc20Proxy = address(new ERC20ReserveProxy());
        // Initialize Token Proxy Contract
        ERC20ReserveProxy(erc20Proxy).initialize(
            msg.sender,
            address(this),
            TOKEN_IDS.current()
        );
    }

    function spawnCollection(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        bool _burnable
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        createCollection(_name, _symbol, _tokenUri, _burnable);
        // Deploy ERC721 Proxy Conract
        address erc721Proxy = address(new ERC721ReserveProxy());
        // Initialize Token Proxy Contract
        ERC721ReserveProxy(erc721Proxy).initialize(
            msg.sender,
            address(this),
            NFT_COLLECTION_IDS.current()
        );
    }

    function mint(
        address account,
        uint256 id,
        uint256 cID,
        uint256 amount,
        bytes memory data
    )
        public
        onlyRole(OPERATOR_ROLE)
        verifyMint(account, id, cID, amount, data)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory cIDs,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyRole(OPERATOR_ROLE)
        verifyBatchMint(to, ids, cIDs, amounts, data)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function getIndexNft(
        uint256 cID,
        uint256 index
    ) public view returns (uint256) {
        return NFT_COLLECTIONS[cID].nfts[index];
    }

    function getOwnerNfts(
        uint256 cID,
        address account
    ) public view returns (uint256[] memory) {
        return NFT_COLLECTIONS[cID].owned[account];
    }

    function setBaseURI(
        string memory newuri,
        uint256 cId
    ) public onlyRole(OPERATOR_ROLE) {
        NFT_COLLECTIONS[cId].baseUri = newuri;
    }

    function setTokenUri(
        uint256 id,
        string memory newuri
    ) public onlyRole(OPERATOR_ROLE) {
        TOKEN_RESERVE[id].uri = newuri;
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory tokenURI = TOKEN_RESERVE[tokenId].uri;
        string memory baseURI = NFT_COLLECTIONS[TOKEN_COLLECTION[tokenId]]
            .baseUri;

        // If token URI is set, concatenate base URI and tokenURI (via string.concat).
        return
            bytes(tokenURI).length > 0
                ? string.concat(baseURI, tokenURI)
                : super.uri(tokenId);
    }

    function uri(
        uint256 tokenId,
        uint256 cID
    ) public view virtual returns (string memory) {
        string memory tokenURI = TOKEN_RESERVE[tokenId].uri;
        string memory baseURI = NFT_COLLECTIONS[cID].baseUri;

        // If token URI is set, concatenate base URI and tokenURI (via string.concat).
        return
            bytes(tokenURI).length > 0
                ? string.concat(baseURI, tokenURI)
                : super.uri(tokenId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        if (TOKEN_COLLECTION[id] > 0) {
            removeNFTId(account, id);
        }
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; i++) {
            if (TOKEN_COLLECTION[ids[i]] > 0) {
                removeNFTId(account, ids[i]);
            }
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        for (uint256 i = 0; i < ids.length; i++) {
            if (TOKEN_COLLECTION[ids[i]] > 0) {
                transferNFTData(from, to, i);
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //
    // Overrides required by Solidity.
    //
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
        super._mint(account, id, amount, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC1155ReceiverUpgradeable,
            ERC1155Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
