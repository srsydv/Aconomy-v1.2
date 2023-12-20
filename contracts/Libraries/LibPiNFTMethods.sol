// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../utils/LibShare.sol";

library LibPiNFTMethods {
    struct Commission {
        LibShare.Share commission;
        bool isValid;
        uint256 validationExpiration;
    }

    function setExpiration(Commission storage commission, uint256 _newExpiration) external {
        require(_newExpiration > block.timestamp);
        require(commission.validationExpiration < block.timestamp);
        commission.validationExpiration = _newExpiration;
    }
}