// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/LibShare.sol";
import "./piNFT.sol";
import "./AconomyERC2771Context.sol";

contract piNFTMethods is
    ReentrancyGuardUpgradeable,
    AconomyERC2771Context,
    PausableUpgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{

    address public piNFTaddress;

    // tokenId => commission
    mapping(uint256 => LibPiNFTMethods.Commission) public validatorCommissions;

    // tokenId => token contract
    mapping(uint256 => address[]) public erc20Contracts;

    // TokenId => Owner Address
    mapping(uint256 => address) public NFTowner;

    // tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) public erc20Balances;

    // tokenId => (token contract => token contract index)
    mapping(uint256 => mapping(address => uint256)) public erc20ContractIndex;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address trustedForwarder, address _piNFTaddress) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        AconomyERC2771Context_init(trustedForwarder);
        piNFTaddress = _piNFTaddress;
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function addERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value,
        uint256 _expiration,
        uint96 _commission,
        LibShare.Share[] memory royalties
    ) public whenNotPaused nonReentrant{
        require(piNFT(piNFTaddress).exists(_tokenId));
        require(_erc20Contract != address(0));
        require(_value != 0);
        LibPiNFTMethods.setExpiration(validatorCommissions[_tokenId], _expiration);
        if (erc20Contracts[_tokenId].length >= 1) {
            require(
                _erc20Contract ==
                    erc20Contracts[_tokenId][0],
                "invalid"
            );
            LibShare.setCommission(validatorCommissions[_tokenId].commission, _commission);
            setRoyaltiesForValidator(
                _tokenId,
                _commission,
                royalties
            );
        } else {
            LibShare.setCommission(validatorCommissions[_tokenId].commission, _commission);
            validatorCommissions[_tokenId].isValid = true;
            setRoyaltiesForValidator(
                _tokenId,
                _commission,
                royalties
            );
        }
        NFTowner[_tokenId] = IERC721Upgradeable(
            address(this)
        ).ownerOf(_tokenId);
        updateERC20(_tokenId, _erc20Contract, _value);
        require(
            IERC20Upgradeable(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _value
            )
        );
        emit ERC20Added(
            msg.sender,
            _tokenId,
            _erc20Contract,
            _value
        );
    }

    function updateERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(
            IERC721Upgradeable(address(this)).ownerOf(_tokenId) !=
                address(0), "wrong owner"
        );
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][
            _erc20Contract
        ];
        if (erc20Balance == 0) {
            erc20ContractIndex[_tokenId][
                _erc20Contract
            ] = erc20Contracts[_tokenId].length;
            erc20Contracts[_tokenId].push(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
    }

    


}




