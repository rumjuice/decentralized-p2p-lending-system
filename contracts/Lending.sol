//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";
import "./BaseContract.sol";

/// @title Main lending Contract
/// @author Rav, Jainam, Dhani, Hossein
/// @notice P2P lending smart contract
/// @dev P2P lending smart contract
contract Lending is BaseContract {
    uint8 public interestRate;

    constructor() {
        interestRate = 10;
        /// @notice Dummy loan request for index 0
        /// @dev because in borrowerLoanRequest mapping, it will return 0 if the address is not found
        loanRequests.push(
            LoanRequest(address(0), address(0), 0, 0, 0, LoanStatus.NEW)
        );
    }

    /// @dev we use external visibility to save gas because we know some of these functions can only be called externally

    /// @notice Owner can register borrower
    /// @param _newBorrower (address) borower address
    function registerBorrower(address _newBorrower)
        external
        onlyOwners
        isValidAddress(_newBorrower)
    {
        borrowers[_newBorrower] = true;
    }

    /// @notice Owner can unregister borrower
    /// @param _removeBorrower (address) borrower address
    function unregisterBorrower(address _removeBorrower)
        external
        onlyOwners
        isValidAddress(_removeBorrower)
    {
        borrowers[_removeBorrower] = false;
    }

    /// @notice Owner can register lenders
    /// @param _newLender (address) lender address
    function registerLender(address _newLender)
        external
        onlyOwners
        isValidAddress(_newLender)
    {
        lenders[_newLender] = true;
    }

    /// @notice Owner can unregister lenders
    /// @param _removeLender (address) lender address
    function unregisterLender(address _removeLender)
        external
        onlyOwners
        isValidAddress(_removeLender)
    {
        borrowers[_removeLender] = false;
    }

    /// @notice Borrower can deposit money
    /// @dev Payable function to receive deposit from borrower
    function depositMoney()
        external
        payable
        onlyBorrowers
        isValidAmountSent
        hasEnoughBalance
        hasNoActiveLoan
    {
        /// @notice Deposit must be less than credit score limit
        require(
            msg.value <= (borrowerCreditScore[msg.sender] + 1) * 1 ether,
            "Your deposit must equal or less than (your credit score + 1) * 1 ether"
        );
        deposits[msg.sender] += msg.value;
    }

    /// @notice Get borrower's deposit balance
    /// @return (uint256)
    function getDepositBalance() external view onlyBorrowers returns (uint256) {
        return deposits[msg.sender];
    }

    /// @notice Borrower can withdraw their deposit
    /// @dev If borrower has deposit and has no active loan
    function withdrawDeposit()
        external
        onlyBorrowers
        hasNotZeroDepositBalance
        hasNoActiveLoan
        preventRecursion
    {
        uint256 _amount = deposits[msg.sender];
        deposits[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to withdraw");
    }

    /// @notice Borrower can request a loan based on their credit score
    function requestLoan()
        external
        onlyBorrowers
        hasNotZeroDepositBalance
        hasNoActiveLoan
    {
        /// @notice Checking the credit score to define the max amount that can be lent
        // instead of giving power of unlimited depositing to borrowers,
        /// @dev we can extend credit levels up to 10 or more.
        // 0 level credit score limit is 1 Eth.
        // 1 level credit score limit is 2 Eth.
        // 2 level credit score limit is 3 Eth.
        uint256 _maxAmount;
        uint8 _creditScore = borrowerCreditScore[msg.sender];
        if (_creditScore == 0) {
            _maxAmount = 1;
        } else if (_creditScore == 1) {
            _maxAmount = 2;
        } else if (_creditScore == 2) {
            _maxAmount = 3;
        }

        /// @dev Push loan request object to loan requests array
        // initialize lender with 0 address
        loanRequests.push(
            LoanRequest({
                lender: address(0),
                borrower: msg.sender,
                amount: _maxAmount,
                interestRate: interestRate,
                creditScore: borrowerCreditScore[msg.sender],
                status: LoanStatus.NEW
            })
        );
        /// @dev Get the array index
        uint256 _index = loanRequests.length - 1;
        /// @dev Put the index into borrower loan mapping
        borrowerLoanRequest[msg.sender] = _index;

        /// @notice freeze deposit amount (50% of loan request)
        /// @dev subtract returned amount from deposit balance of borrower
        deposits[msg.sender] -= _maxAmount;
    }

    function getLoanList()
        external
        view
        notBorrowers
        returns (LoanRequest[] memory)
    {
        return loanRequests;
    }

    /// @notice Function for lenders to provide lending
    /// @dev The lender selects one of the loan requests and transfers the requested amount to the borrower
    /// @param _index (uint256) loan request index
    function lending(uint256 _index) external payable onlyLenders {
        /// @dev Verify if the selected loan request is valid
        require(_index > 0 && loanRequests[_index].amount > 0, "Invalid loan");
        /// @dev Check if the loan status is new
        require(
            loanRequests[_index].status == LoanStatus.NEW,
            "Loan is not open"
        );
        /// @dev Verifying the transferred value of the lender according to the borrower's requested loan amount
        require(
            msg.value == loanRequests[_index].amount * 1 ether,
            "Incorrect amount"
        );
        /// @dev Update the loan object
        loanRequests[_index].lender = msg.sender;
        loanRequests[_index].status = LoanStatus.ON_LOAN;
        /// @dev Send the requested amount to the borrower
        (bool sent, ) = loanRequests[_index].borrower.call{
            value: msg.value * 1 ether
        }("");
        require(sent, "Failed to lend");
    }

    /// @notice Get the amount borrowed
    /// @return (uint256)
    function findBorrowerAmountInLoanRequests()
        internal
        view
        returns (uint256)
    {
        return loanRequests[borrowerLoanRequest[msg.sender]].amount;
    }

    /// @notice Payout function for borrower to pay the debt
    function payout() external payable onlyBorrowers {
        /// @dev Checking if borrower has active loan
        uint256 _index = borrowerLoanRequest[msg.sender];
        require(
            loanRequests[_index].status == LoanStatus.ON_LOAN,
            "You have no active loan"
        );
        /// @dev Calculate the payback amount (principal + interest)
        uint256 _debtAmount = findBorrowerAmountInLoanRequests();
        uint256 _returnPaybackAmount = _debtAmount +
            ((_debtAmount * interestRate) / 100);
        /// @dev Check if the value sent by the borrower is equal to their loan amount
        require(
            msg.value == _returnPaybackAmount * 1 ether,
            "Amount is not correct!"
        );
        /// @dev Get the lender address
        address payable _lenderAddress = payable(
            loanRequests[borrowerLoanRequest[msg.sender]].lender
        );
        /// @dev Updating loan status to PAID
        loanRequests[_index].status == LoanStatus.PAID;
        /// @dev Paying back to the lender
        (bool sent, ) = _lenderAddress.call{
            value: _returnPaybackAmount * 1 ether
        }("");
        require(sent, "Failed to pay");
        /// @dev Take 1% processing fee for this contract profit, deducted from borrower's deposit
        takeProcessingFee(msg.sender, _debtAmount);
        /// @dev Increment borrower's credit score
        if (borrowerCreditScore[msg.sender] < 2) {
            borrowerCreditScore[msg.sender]++;
        }
    }

    /// @notice Get loan status
    /// @param _borrower (address) borrower address
    /// @return (string)
    function getLoanStatus(address _borrower)
        external
        view
        notLenders
        returns (string memory)
    {
        uint256 _index = borrowerLoanRequest[_borrower];
        require(_index > 0, "You have no active loan");

        return Utils.getStatus(loanRequests[_index].status);
    }

    /// @notice Get smart contract balance
    /// @return (uint256)
    function balanceOfContract() external view onlyOwners returns (uint256) {
        return address(this).balance;
    }

    /// @notice Take transaction fee which is 1% of borrowed amount
    /// @dev Whenever a borrower pays back debt, their address and amount needs to be passed to this method
    /// @param _borrower (address) borrower address
    /// @param _borrowedAmount (uint256) borrowed amount
    function takeProcessingFee(address _borrower, uint256 _borrowedAmount)
        internal
    {
        uint256 _borrowerDeposit = deposits[_borrower];
        uint256 _fee = Utils.percentage(_borrowedAmount, 1);
        if (_fee > _borrowerDeposit) {
            contractProfit += _borrowerDeposit;
            deposits[_borrower] = 0;
        } else {
            deposits[_borrower] = _borrowerDeposit - _fee;
            contractProfit += _fee;
        }
    }

    /// @notice Owner can set interest rate
    /// @param _interestRate (uint8)
    function setInterestRate(uint8 _interestRate)
        external
        isValidInterestRate(_interestRate)
        onlyOwners
    {
        interestRate = _interestRate;
    }

    /// @notice Owner can withdraw smart contract balance
    function withdrawAll() external onlyOwners {
        (bool sent, ) = msg.sender.call{value: this.balanceOfContract()}("");
        require(sent, "Failed to withdraw");
    }

    /// @notice Lender can force close their loan
    /// @dev In case the borrower is unable to pay back, lender will get all the borrower's deposit
    /// @param _borrowerAddress (address)
    function forceCloseLoanRequest(address _borrowerAddress)
        external
        onlyLenders
    {
        /// @dev Get loan request index
        uint256 _loanIndex = borrowerLoanRequest[_borrowerAddress];

        /// @dev Check if loan exist
        require(_loanIndex > 0, "Loan not found");

        /// @dev Check if lender has active loan with given borrower
        require(
            loanRequests[_loanIndex].status == LoanStatus.ON_LOAN &&
                loanRequests[_loanIndex].lender == msg.sender,
            "You have no loan payout"
        );

        /// @dev change the status of the loan request
        loanRequests[_loanIndex].status = LoanStatus.CLOSED_BY_LENDER;

        /// @dev change borrower credit score to 0 for not returning loan
        borrowerCreditScore[_borrowerAddress] = 0;

        /// @dev 50% of loan amount should be returned
        uint256 amount = (loanRequests[_loanIndex].amount / 2);

        /// @dev Empty borrower's deposit
        deposits[_borrowerAddress] = 0;

        /// @dev Remove borrower loan request
        delete borrowerLoanRequest[_borrowerAddress];

        /// @dev send the money to lender
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to withdraw");
    }
}
