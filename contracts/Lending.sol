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
    // Keep balance amount of smart contract (profit)
    uint256 private balanceAmountOfSmartContractProfit;
    enum LoanStatus {
        NEW,
        ON_LOAN,
        PAID,
        CANCELED,
        CLOSED_BY_LENDER
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
    // mapping of borrower address to credit score
    mapping(address => uint8) private borrowerCreditScores;

    mapping(address => bool) private mutex;

    //#region

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
        require(msg.value <= (borrowerCreditScores[msg.sender] + 1) * 1 ether, "Your deposit must equal or less than (your credit score + 1) * 1 ether");
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
        // Checking the credit score to define the max amount for the deposit.
        // ***
        // Instead of giving power of unlimited depositing to borrowers,
        // we can extend credit levels up to 10 or more.
        // ***
        // 0 level credit score limit is 1 Eth.
        // 1 level credit score limit is 2 Eth.
        // 2 level credit score limit is 3 Eth.
        uint256 _maxAmount;
        uint8 creditlevel = borrowerCreditScores[msg.sender];
        if (creditlevel==0) {
            _maxAmount= 1;
        } else if (creditlevel==1) {
            _maxAmount= 2;
        } else if (creditlevel==2) {
            _maxAmount= 2;
        }         

        // create loan object
        loanRequests.push(
            LoanRequest({
                lender: address(0),
                amount: _maxAmount,
                interestRate: interestRate,
                creditScore: borrowerCreditScores[msg.sender],
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
            balanceAmountOfSmartContractProfit += borrowerDeposit;
            deposits[_borrower] = 0;
        } else {
            deposits[_borrower] = borrowerDeposit - fee;
            balanceAmountOfSmartContractProfit += fee;
        }
    }

    // Finding the borrower amount field in the loan request array through their address.
    function findBorrowerAmountInLoanRequests() internal view returns (uint256) {
        return loanRequests[borrowerLoanRequest[msg.sender]].amount;
        // description:
        //uint256 _index = borrowerLoanRequest[msg.sender];
        //uint256 _amount = loanRequests[_index].amount;
        //return _amount;
    }

    // The borrower pays the debt.
    function borrowerPaysDebt() external payable onlyBorrowers returns (bool){
        // Checking if the borrower has an active loan (status == ON_LOAN)
        uint _index=borrowerLoanRequest[msg.sender];
        require(loanRequests[_index].status == LoanStatus.ON_LOAN , "You have no active loan");
        uint256 debtAmount = findBorrowerAmountInLoanRequests();  
        uint256 returnPaybackAmount = debtAmount + ((debtAmount * interestRate) / 100);
        // Check if the value sent by the borrower is equal to their (his/her) loan amount.
        require(msg.value == returnPaybackAmount * 1 ether, "Your payback amount is not correct!");
        // Finding the lender address associated with this borrower
        // in order to pay the debt to the lender 
        address payable LenderAddressAssociatedWithThisBorrower = payable(loanRequests[borrowerLoanRequest[msg.sender]].lender);
        // Paying back to the lender.
        LenderAddressAssociatedWithThisBorrower.transfer(returnPaybackAmount * 1 ether);
        // Updating loan status to PAID.
        loanRequests[_index].status == LoanStatus.PAID;
        //Processing of taking the fee amount that will be added to the smart contract balance
        //and will be deducted from the borrower deposit.       
         takeProcessingFee(msg.sender, debtAmount);
         if (borrowerCreditScores[msg.sender]<2){
                borrowerCreditScores[msg.sender]++;
         }
         return true;
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
