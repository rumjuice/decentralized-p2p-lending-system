//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error NotRegisteredOwner();
error NotRegisteredBorrower();
error NotRegisteredLender();
error DepositCannotBeZero();
error NotEnoughFunds();
error NoFundsInDeposit();
error BurnAddressProhibited();

contract Lending {
    //#region State variables
    mapping(address => bool) private owners;
    mapping(address => uint256) private deposits;
    mapping(address => bool) private borrowers;
    mapping(address => uint256) private lendersInvestment;
    mapping(address => bool) private lenders;



    //#region

    constructor() { 
        // TODO this should be replaced with our address
        // so that we're added as the contract owners (TBD)
        owners[address(uint160(bytes20("0x1")))] = true;
        owners[address(uint160(bytes20("0x2")))] = true;
        owners[address(uint160(bytes20("0x3")))] = true;
        owners[msg.sender]=true;
    }

    //#region Modifiers
    modifier onlyOwners() {
        if(!owners[msg.sender])
            revert NotRegisteredOwner();
        _;
    }

    modifier onlyBorrowers() {
        if(!borrowers[msg.sender])
            revert NotRegisteredBorrower();
        _;
    }

    modifier onlyLenders() {
        if(!lenders[msg.sender])
            revert NotRegisteredLender();
        _;
    }

    modifier isValidAmountSent() {
        if(msg.value <= 0)
            revert DepositCannotBeZero();
        _;
    }

    modifier hasEnoughBalance() {
        if(msg.sender.balance < msg.value)
            revert NotEnoughFunds();
        _;
    }

    modifier isValidAddress(address addr) {
        if(addr == 0x0000000000000000000000000000000000000000)
            revert BurnAddressProhibited();
        _;
    }

    modifier hasNotZeroDepositBalance() {
        if(deposits[msg.sender] <= 0)
            revert NoFundsInDeposit();
        _;
    }

    //#region

    // we use external to save gas because we know this function can only be called externally
    function depositMoney() external payable onlyBorrowers isValidAmountSent hasEnoughBalance {
        deposits[msg.sender] += msg.value;
    }

    function getDepositBalance() external view onlyBorrowers returns (uint256) {
        return deposits[msg.sender];
    }

    function withdrawDeposit() external payable onlyBorrowers hasNotZeroDepositBalance {
        uint256 _amount = deposits[msg.sender];
        deposits[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to withdraw");
    }


    //owners should register borrowers
    function registerBorrower(address newBorrower) external onlyOwners isValidAddress(newBorrower) {
        borrowers[newBorrower] = true;
    }

    //owners should unregister not needed borrowers
    function unregisterBorrower(address removedBorrower) external onlyOwners isValidAddress(removedBorrower) {
        borrowers[removedBorrower] = false;
    }

    //get smart contract balance
    function balanceOfContract() external view returns(uint){
        
        return address(this).balance;
    }

    //owners should register lenders
    function registerLender(address newLender) external onlyOwners isValidAddress(newLender) {
        lenders[newLender] = true;
    }

    //owners should unregister lender
    function unregisterLender(address removedLender) external onlyOwners isValidAddress(removedLender) {
        borrowers[removedLender] = false;
    }

}
