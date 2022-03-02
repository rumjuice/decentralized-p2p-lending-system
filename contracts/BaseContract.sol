//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";

/// @notice Error declarations
error NotRegisteredOwner();
error NotRegisteredBorrower();
error NotRegisteredLender();
error DepositCannotBeZero();
error NotEnoughFunds();
error NoFundsInDeposit();
error BurnAddressProhibited();
error HasActiveLoan();
error OnlyOwnersAndBorrowersCanAccess();
error InvalidInterestRate();
error OnlyOwnersAndLendersCanAccess();

/// @title Base Contract
/// @author Rav, Jainam, Dhani, Hossein
/// @notice High-level contract to store information
/// @dev Interface of the main contract so that the code is clean, maintainable, and reusable
contract BaseContract is Context {
    /// @notice Contract owners
    mapping(address => bool) private owners;
    /// @notice Store list of borrowers
    mapping(address => bool) internal borrowers;
    /// @notice Store list of lenders
    mapping(address => bool) internal lenders;
    /// @notice Store borrower's deposit
    mapping(address => uint256) internal deposits;
    /// @notice Store index of borrower's loan request
    mapping(address => uint256) internal borrowerLoanRequest;
    /// @notice Store borrower's credit score
    mapping(address => uint8) internal borrowerCreditScore;
    /// @dev Utility variable to prevent recursion
    mapping(address => bool) private mutex;
    /// @notice Store balance of smart contract (profit)
    uint256 internal contractProfit;
    /// @notice Store list of loan request
    LoanRequest[] internal loanRequests;

    /// @notice Loan status
    enum LoanStatus {
        NEW,
        ON_LOAN,
        PAID,
        CANCELED,
        CLOSED_BY_LENDER
    }

    /// @notice Loan request object
    struct LoanRequest {
        address lender;
        address borrower;
        uint256 amount;
        uint8 interestRate;
        uint8 creditScore;
        LoanStatus status;
    }

    constructor() {
        /// @notice Initialize owners contract address
        // Ramdhani address
        owners[address(0x9321ef8Ccf26Ca4d64F7213076B3BAb0F6253E96)] = true;
        // Jainam address
        owners[address(0xffDdE6391761A8d27E1579a094bCC55C6C4799E9)] = true;
        // Hossein address
        owners[address(0xf859ECf4Ea6322F706F908aAA76702c3CA7faEbB)] = true;
        // Ravshan address
        owners[address(0x42Bd936410fE89CFfB8cbb3934A6FD3D6F76cB2a)] = true;
    }

    /// @notice Only owners can execute
    modifier onlyOwners() {
        if (!owners[msg.sender]) revert NotRegisteredOwner();
        _;
    }

    /// @notice Only borrowers can execute
    modifier onlyBorrowers() {
        if (!borrowers[msg.sender]) revert NotRegisteredBorrower();
        _;
    }

    /// @notice Only lenders can execute
    modifier onlyLenders() {
        if (!lenders[msg.sender]) revert NotRegisteredLender();
        _;
    }

    /// @notice Borrowers can't execute
    modifier notBorrowers() {
        if (!(owners[msg.sender] || lenders[msg.sender]))
            revert OnlyOwnersAndBorrowersCanAccess();
        _;
    }

    /// @notice Lenders can't execute
    modifier notLenders() {
        if (!(owners[msg.sender] || borrowers[msg.sender]))
            revert OnlyOwnersAndLendersCanAccess();
        _;
    }

    /// @notice Amount must be more than 0
    modifier isValidAmountSent() {
        if (msg.value <= 0) revert DepositCannotBeZero();
        _;
    }

    /// @notice Ensure caller have enough balance
    modifier hasEnoughBalance() {
        if (msg.sender.balance < msg.value) revert NotEnoughFunds();
        _;
    }

    /// @notice Ensure address is valid
    modifier isValidAddress(address _addr) {
        if (_addr == 0x0000000000000000000000000000000000000000)
            revert BurnAddressProhibited();
        _;
    }

    /// @notice Ensure deposit is not 0
    modifier hasNotZeroDepositBalance() {
        if (deposits[msg.sender] <= 0) revert NoFundsInDeposit();
        _;
    }

    /// @notice Ensure borrowers doesn't have active loan
    modifier hasNoActiveLoan() {
        if (borrowerLoanRequest[msg.sender] > 0) revert HasActiveLoan();
        _;
    }

    /// @notice Prevent multiple calls to the function
    /// @dev Prevent function recursion
    modifier preventRecursion() {
        if (!mutex[msg.sender]) {
            mutex[msg.sender] = true;
            _;
        }
        mutex[msg.sender] = false;
    }

    /// @notice Ensure interest is not more than 100
    modifier isValidInterestRate(uint8 _interestRate) {
        if (_interestRate > 100) revert InvalidInterestRate();
        _;
    }
}
