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

contract Lending {
    //#region State variables
    uint8 public interest;
    enum LoanStatus {
        NEW,
        ON_LOAN,
        PAID
    }
    struct LoanRequest {
        address lender;
        uint256 amount;
        uint8 interest;
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
    LoanRequest[] public loanRequests;
    // mapping of borrower address to loan request index
    mapping(address => uint256) public borrowerLoanRequest;
    mapping(address => uint256) private lendersInvestment;
    mapping(address => bool) private lenders;

    mapping(address => bool) private mutex;

    //#region

    constructor() {
        // TODO this should be replaced with our address
        // so that we're added as the contract owners (TBD)
        owners[address(uint160(bytes20("0x1")))] = true;
        owners[address(uint160(bytes20("0x2")))] = true;
        owners[address(uint160(bytes20("0x3")))] = true;
        owners[msg.sender] = true;
        // default interest rate
        interest = 10;
        // put dummy loan request for index 0
        // because in borrowerLoanRequest mapping, it will return 0 if address not found
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
        payable
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
                interest: interest,
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
        returns (string memory)
    {
        // TODO merge this into one modifier and add only lenders
        // I think we need to refactor the modifiers
        require(
            owners[msg.sender] || borrowers[msg.sender],
            "Only owners or borrowers"
        );

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
}
