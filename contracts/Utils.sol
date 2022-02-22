//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    function percentage(uint256 _amount, uint8 _rate)
        internal
        pure
        returns (uint256)
    {
        // Solidity > 0.8 already have built-in overflow checking
        return (_amount * _rate) / 100;
    }

    // Get loan status in string
    function getStatus(uint8 _status) internal pure returns (string memory) {
        return _status == 0 ? "NEW" : _status == 1 ? "ON_LOAN" : "PAID";
    }
}
