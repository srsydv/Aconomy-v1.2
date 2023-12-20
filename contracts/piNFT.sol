// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./AconomyERC2771Context.sol";
import "./utils/LibShare.sol";
import "./Libraries/LibPiNFTMethods.sol";

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

    // // tokenId => commission
    // mapping(uint256 => LibPiNFTMethods.Commission) public validatorCommissions;

    // // tokenId => token contract
    // mapping(uint256 => address[]) public erc20Contracts;

    // // TokenId => Owner Address
    // mapping(uint256 => address) public NFTowner;

    // // tokenId => (token contract => balance)
    // mapping(uint256 => mapping(address => uint256)) public erc20Balances;

    // // tokenId => (token contract => token contract index)
    // mapping(uint256 => mapping(address => uint256)) public erc20ContractIndex;

    event RoyaltiesSetForTokenId(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event RoyaltiesSetForValidator(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event ERC20Added(
        address indexed from,
        uint256 indexed tokenId,
        address indexed erc20Contract,
        uint256 value
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
        address _erc20Contract,
        uint256 _value,
        uint256 _expiration,
        uint96 _commission,
        LibShare.Share[] memory royalties
    ) public whenNotPaused nonReentrant returns (uint256) {
        require(_to != address(0),"Zero Address");
        require(_erc20Contract != address(0),"Zero Address");
        require(_value != 0, "Zero Value");
        uint256 tokenId_ = _tokenIdCounter.current();
        _setRoyaltiesByTokenId(tokenId_, royalties);
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        addERC20(tokenId_, _erc20Contract, _value, _expiration, _commission, royalties);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }


    function mintValidatedNFT(
        address _to,
        string memory _uri,
        address _erc20Contract,
        uint256 _value,
        uint256 _expiration,
        uint96 _commission,
        LibShare.Share[] memory royalties
    ) public whenNotPaused nonReentrant returns (uint256) {
        // require(_to != address(0),"Zero Address");
        require(_erc20Contract != address(0),"Zero Address");
        require(_value != 0, "Zero Value");
        uint256 tokenId_ = _tokenIdCounter.current();
        _setRoyaltiesByTokenId(tokenId_, royalties);
        _safeMint(piNFTMethodsAddress, tokenId_);
        _setTokenURI(tokenId_, _uri);
        piNFTMethods(piNFTMethodsAddress).addValidator(address(this), tokenId_, _to);
        // piNFTMethods(piNFTMethodsAddress).addERC20(tokenId_, _erc20Contract, _value, _expiration, _commission, royalties);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }


    // function addERC20(
    //     uint256 _tokenId,
    //     address _erc20Contract,
    //     uint256 _value,
    //     uint256 _expiration,
    //     uint96 _commission,
    //     LibShare.Share[] memory royalties
    // ) public whenNotPaused nonReentrant{
    //     require(_exists(_tokenId));
    //     require(_erc20Contract != address(0));
    //     require(_value != 0);
    //     LibPiNFTMethods.setExpiration(validatorCommissions[_tokenId], _expiration);
    //     if (erc20Contracts[_tokenId].length >= 1) {
    //         require(
    //             _erc20Contract ==
    //                 erc20Contracts[_tokenId][0],
    //             "invalid"
    //         );
    //         LibShare.setCommission(validatorCommissions[_tokenId].commission, _commission);
    //         setRoyaltiesForValidator(
    //             _tokenId,
    //             _commission,
    //             royalties
    //         );
    //     } else {
    //         LibShare.setCommission(validatorCommissions[_tokenId].commission, _commission);
    //         validatorCommissions[_tokenId].isValid = true;
    //         setRoyaltiesForValidator(
    //             _tokenId,
    //             _commission,
    //             royalties
    //         );
    //     }
    //     NFTowner[_tokenId] = IERC721Upgradeable(
    //         address(this)
    //     ).ownerOf(_tokenId);
    //     updateERC20(_tokenId, _erc20Contract, _value);
    //     require(
    //         IERC20Upgradeable(_erc20Contract).transferFrom(
    //             msg.sender,
    //             address(this),
    //             _value
    //         )
    //     );
    //     emit ERC20Added(
    //         msg.sender,
    //         _tokenId,
    //         _erc20Contract,
    //         _value
    //     );
    // }

    // function updateERC20(
    //     uint256 _tokenId,
    //     address _erc20Contract,
    //     uint256 _value
    // ) private {
    //     require(
    //         IERC721Upgradeable(address(this)).ownerOf(_tokenId) !=
    //             address(0), "wrong owner"
    //     );
    //     if (_value == 0) {
    //         return;
    //     }
    //     uint256 erc20Balance = erc20Balances[_tokenId][
    //         _erc20Contract
    //     ];
    //     if (erc20Balance == 0) {
    //         erc20ContractIndex[_tokenId][
    //             _erc20Contract
    //         ] = erc20Contracts[_tokenId].length;
    //         erc20Contracts[_tokenId].push(_erc20Contract);
    //     }
    //     erc20Balances[_tokenId][_erc20Contract] += _value;
    // }

    function setRoyaltiesForValidator(
        uint256 _tokenId,
        uint256 _commission,
        LibShare.Share[] memory royalties
    ) internal {
        require(royalties.length <= 10);
        delete royaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0);
            royaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4900 - _commission, "overflow");

        emit RoyaltiesSetForValidator(_tokenId, royalties);
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

    function exists(uint256 _tokenId) external view returns(bool){
        return _exists(_tokenId);
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