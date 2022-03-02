//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseContract.sol";

/// @title Utility contract
/// @author Rav, Jainam, Dhani, Hossein
/// @notice Provides utility function
/// @dev Pure function for calculation and status mapping
library Utils {
    /// @notice Calculate percentage of given amount
    /// @dev Calculate percentage of given amount
    /// @param _amount (uint256)
    /// @param _percentage (uint8)
    /// @return  (uint256)
    function percentage(uint256 _amount, uint8 _percentage)
        internal
        pure
        returns (uint256)
    {
        /// @dev Solidity > 0.8 already have built-in overflow checking
        return (_amount * _percentage) / 100;
    }

    /// @notice Get status in text
    /// @dev Get status in string based on LoanStatus enum
    /// @param _status (LoanStatus)
    /// @return _statusName (string)
    function getStatus(BaseContract.LoanStatus _status)
        internal
        pure
        returns (string memory _statusName)
    {
        if (_status == BaseContract.LoanStatus.NEW) return "NEW";
        if (_status == BaseContract.LoanStatus.ON_LOAN) return "ON_LOAN";
        if (_status == BaseContract.LoanStatus.PAID) return "PAID";
        if (_status == BaseContract.LoanStatus.CANCELED) return "CANCELED";
        if (_status == BaseContract.LoanStatus.CLOSED_BY_LENDER)
            return "CLOSED_BY_LENDER";
    }
}
