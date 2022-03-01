//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";
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
contract BaseContract is Context {
    mapping(address => bool)  owners;
    mapping(address => bool)  borrowers;
    mapping(address => bool)  lenders;
    mapping(address => uint256)  deposits;
    mapping(address => bool)  mutex;
    mapping(address => uint256)  borrowerLoanRequest;
    // mapping of borrower address to loan request index
    // mapping(address => uint256) private borrowerLoanRequest;
    mapping(address => uint256)  lendersInvestment;
    // mapping(address => bool) private lenders;
    // mapping of borrower address to credit score
    mapping(address => uint8)  borrowerCreditScores;

        constructor() {
        // Owners contract address
        // Ramdhani address
        owners[address(0x9321ef8Ccf26Ca4d64F7213076B3BAb0F6253E96)] = true;
        // Jainam address
        owners[address(0xffDdE6391761A8d27E1579a094bCC55C6C4799E9)] = true;
        // Hossein address
        owners[address(0xf859ECf4Ea6322F706F908aAA76702c3CA7faEbB)] = true;
        // Ravshan address
        owners[address(0x42Bd936410fE89CFfB8cbb3934A6FD3D6F76cB2a)] = true;

        // TODO remove this when we're finished
        owners[msg.sender] = true;

    }

     modifier onlyOwners() {
        if (!owners[msg.sender]) revert NotRegisteredOwner();
        _;
    }

    modifier onlyBorrowers() {
        if (!borrowers[msg.sender]) revert NotRegisteredBorrower();
        _;
    }

    modifier notBorrowers() {
        if (!(owners[msg.sender] || lenders[msg.sender]))
            revert OnlyOwnersAndBorrowersCanAccess();
        _;
    }

    modifier notLenders() {
        if (!(owners[msg.sender] || borrowers[msg.sender]))
            revert OnlyOwnersAndLendersCanAccess();
        _;
    }

    modifier onlyLenders() {
        if (!lenders[msg.sender]) revert NotRegisteredLender();
        _;
    }

    modifier isValidAmountSent() {
        if (msg.value <= 0) revert DepositCannotBeZero();
        _;
    }

    modifier hasEnoughBalance() {
        if (msg.sender.balance < msg.value) revert NotEnoughFunds();
        _;
    }

    modifier isValidAddress(address _addr) {
        if (_addr == 0x0000000000000000000000000000000000000000)
            revert BurnAddressProhibited();
        _;
    }

    modifier hasNotZeroDepositBalance() {
        if (deposits[msg.sender] <= 0) revert NoFundsInDeposit();
        _;
    }
    // modifier to freeze deposit
    modifier hasNoActiveLoan() {
        if (borrowerLoanRequest[msg.sender] > 0) revert HasActiveLoan();
        _;
    }

    modifier preventRecursion() {
        if (!mutex[msg.sender]) {
            mutex[msg.sender] = true;
            _;
        }
        mutex[msg.sender] = false;
    }

    modifier isValidIntererstRate(uint8 _interestRate) {
        if (_interestRate > 100) revert InvalidInterestRate();
        _;
    }

}