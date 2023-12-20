// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./AconomyERC2771Context.sol";
import "./utils/LibShare.sol";

contract piNFT is
    ERC721URIStorageUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AconomyERC2771Context,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // tokenId => royalties
    mapping(uint256 => LibShare.Share[]) internal royaltiesByTokenId;

    mapping(uint256 => LibShare.Share[]) internal royaltiesForValidator;

    event RoyaltiesSetForTokenId(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event RoyaltiesSetForValidator(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event TokenMinted(uint256 tokenId, address to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address tfGelato
    ) public initializer {
        __ERC721_init(_name, _symbol);
        AconomyERC2771Context_init(tfGelato);
        __ERC721URIStorage_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintValidatedNFT(
        address _to,
        string memory _uri,
        LibShare.Share[] memory royalties
    ) public whenNotPaused returns (uint256) {
        require(_to != address(0));
        uint256 tokenId_ = _tokenIdCounter.current();
        _setRoyaltiesByTokenId(tokenId_, royalties);
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }

    function _setRoyaltiesByTokenId(
        uint256 _tokenId,
        LibShare.Share[] memory royalties
    ) internal {
        require(royalties.length <= 10);
        delete royaltiesByTokenId[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0);
            royaltiesByTokenId[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4900, "overflow");

        emit RoyaltiesSetForTokenId(_tokenId, royalties);
    }


    function _msgSender()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (address sender)
    {
        return AconomyERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return AconomyERC2771Context._msgData();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

}