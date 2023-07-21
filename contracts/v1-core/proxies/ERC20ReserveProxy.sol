// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IMultiTokenReserveV1.sol";
import "../utils/getTokenProtocolData.sol";

contract ERC20ReserveProxy is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    ERC20FlashMintUpgradeable,
    UUPSUpgradeable
{
    IMultiTokenReserveV1 public MultiTokenReserve;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address private RESERVE_ADDRESS;
    uint256 private RESERVE_TOKEN_ID;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _contractAdmin, address _multiTokenReserve, uint256 _tokenId) public initializer {
        MultiTokenReserve = IMultiTokenReserveV1(_multiTokenReserve);
        RESERVE_TOKEN_ID = _tokenId;

        __ERC20_init(name(), symbol());
        __ERC20Permit_init(name());
        __ERC20Burnable_init();
        __ERC20Votes_init();
        __ERC20FlashMint_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _contractAdmin);
        _grantRole(MINTER_ROLE, _contractAdmin);
        _grantRole(UPGRADER_ROLE, _contractAdmin);
    }

    function name() public view override returns (string memory) {
        (, , , string memory tokenName, , , , ) = getTokenProtocolData(RESERVE_ADDRESS, RESERVE_TOKEN_ID);
        return tokenName;
    }

    function symbol() public view override returns (string memory) {
        (, , , , string memory tokenSymbol, , , ) = getTokenProtocolData(RESERVE_ADDRESS, RESERVE_TOKEN_ID);
        return tokenSymbol;
    }

    function decimals() public view override returns (uint8) {
        (, , uint8 tokenDecimals, , , , , ) = getTokenProtocolData(RESERVE_ADDRESS, RESERVE_TOKEN_ID);
        return tokenDecimals;
    }

    function totalSupply() public view override returns (uint256) {
        (uint256 tokenTotalSupply, , , , , , , ) = getTokenProtocolData(RESERVE_ADDRESS, RESERVE_TOKEN_ID);
        return tokenTotalSupply;
    }

    function maxSupply() public view returns (uint256) {
        (, uint256 tokenMaxSupply, , , , , , ) = getTokenProtocolData(RESERVE_ADDRESS, RESERVE_TOKEN_ID);
        return tokenMaxSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return MultiTokenReserve.balanceOf(account, RESERVE_TOKEN_ID);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        MultiTokenReserve.safeTransferFrom(
            msg.sender,
            recipient,
            amount,
            RESERVE_TOKEN_ID,
            ""
        );
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        MultiTokenReserve.safeTransferFrom(
            sender,
            recipient,
            amount,
            RESERVE_TOKEN_ID,
            ""
        );
        return true;
    }

    // ERC20Burnable functions
    function burn(uint256 amount) public override {
        MultiTokenReserve.burn(msg.sender, RESERVE_TOKEN_ID, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        MultiTokenReserve.burn(account, RESERVE_TOKEN_ID, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }
}
