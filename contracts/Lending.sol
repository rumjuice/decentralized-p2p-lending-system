//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

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

contract Lending {
    //#region State variables
    uint8 public interestRate;
    enum LoanStatus {
        NEW,
        ON_LOAN,
        PAID
    }
    struct LoanRequest {
        address lender;
        uint256 amount;
        uint8 interestRate;
        uint8 creditScore;
        LoanStatus status;
    }

    // contract owners
    mapping(address => bool) private owners;
    // borrower deposit
    mapping(address => uint256) private deposits;
    // registered borrower address
    mapping(address => bool) private borrowers;
    // list of loan request
    LoanRequest[] private loanRequests;
    // mapping of borrower address to loan request index
    mapping(address => uint256) private borrowerLoanRequest;
    mapping(address => uint256) private lendersInvestment;
    mapping(address => bool) private lenders;

    mapping(address => bool) private mutex;

    //#region

    constructor() {
        // TODO this should be replaced with our address
        // so that we're added as the contract owners
        // Ramdhani address
        owners[address(0x9321ef8Ccf26Ca4d64F7213076B3BAb0F6253E96)] = true;
        owners[address(uint160(bytes20("0x2")))] = true;
        owners[address(uint160(bytes20("0x3")))] = true;
        // TODO remove this when we're finished
        owners[msg.sender] = true;
        // default interestRate
        interestRate = 10;
        // put dummy loan request for index 0
        // because in borrowerLoanRequest mapping, it will return 0 if the address is not found
        loanRequests.push(LoanRequest(address(0), 0, 0, 0, LoanStatus.NEW));
    }

    //#region Modifiers
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

    //#region

    // we use external to save gas because we know these functions can only be called externally

    //owners should register borrowers
    function registerBorrower(address _newBorrower)
        external
        onlyOwners
        isValidAddress(_newBorrower)
    {
        borrowers[_newBorrower] = true;
    }

    //owners should unregister not needed borrowers
    function unregisterBorrower(address _removeBorrower)
        external
        onlyOwners
        isValidAddress(_removeBorrower)
    {
        borrowers[_removeBorrower] = false;
    }

    function depositMoney()
        external
        payable
        onlyBorrowers
        isValidAmountSent
        hasEnoughBalance
        hasNoActiveLoan
    {
        deposits[msg.sender] += msg.value;
    }

    function getDepositBalance() external view onlyBorrowers returns (uint256) {
        return deposits[msg.sender];
    }

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

    function requestLoan()
        external
        onlyBorrowers
        hasNotZeroDepositBalance
        hasNoActiveLoan
    {
        // TODO check credit score for max amount
        // uint256 _maxAmount = creditScore <= 1 ? 0.5 ether : deposits[msg.sender] * 2;

        // create loan object
        loanRequests.push(
            LoanRequest({
                lender: address(0),
                amount: deposits[msg.sender] * 2,
                interestRate: interestRate,
                creditScore: 1,
                status: LoanStatus.NEW
            })
        );
        // get index
        uint256 _index = loanRequests.length - 1;
        // put into borrower loan mapping
        borrowerLoanRequest[msg.sender] = _index;
    }

    function getLoanStatus(address _borrower)
        external
        view
        notLenders
        returns (string memory)
    {
        uint256 _index = borrowerLoanRequest[_borrower];
        require(_index > 0, "You have no active loan");

        return Utils.getStatus(uint8(loanRequests[_index].status));
    }

    //get smart contract balance
    function balanceOfContract() external view onlyOwners returns (uint256) {
        return address(this).balance;
    }

    //owners should register lenders
    function registerLender(address _newLender)
        external
        onlyOwners
        isValidAddress(_newLender)
    {
        lenders[_newLender] = true;
    }

    //owners should unregister lender
    function unregisterLender(address _removeLender)
        external
        onlyOwners
        isValidAddress(_removeLender)
    {
        borrowers[_removeLender] = false;
    }

    //take transaction fee which is 1% borrowed amount
    //whenever a borrower pays back debt, his address and amount needs to be passed to this method
    function takeProcessingFee(address _borrower, uint256 _borrowedAmount)
        internal
    {
        uint256 borrowerDeposit = deposits[_borrower];
        uint256 fee = Utils.percentage(_borrowedAmount, 1);
        if (fee > borrowerDeposit) {
            deposits[_borrower] = 0;
        } else {
            deposits[_borrower] = borrowerDeposit - fee;
        }
    }

    //owners and lenders can access the loanRequests list
    function getLoanList()
        external
        view
        notBorrowers
        returns (LoanRequest[] memory)
    {
        return loanRequests;
    }

    //owners can set interest rate
    function setInterestRate(uint8 _interestRate)
        external
        isValidIntererstRate(_interestRate)
        onlyOwners
    {
        interestRate = _interestRate;
    }
}
