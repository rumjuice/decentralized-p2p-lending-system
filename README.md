
## P2P Lending Smart Contract Solution

### Contributors:

- Ravshan: [LinkedIn](https://www.linkedin.com/in/rmakhmadaliev/) [GitHub](https://github.com/Ravshann)

- Jainam: [LinkedIn](https://www.linkedin.com/in/jainmshah/) [GitHub](https://github.com/naxer-12)

- Hossein: [LinkedIn](https://www.linkedin.com/in/hossein-hesami-5a565b78/) [GitHub](https://github.com/DarioHesami)

- Ramdhani: [LinkedIn](https://www.linkedin.com/in/ramdhaniharis/) [GitHub](https://github.com/rumjuice)

#

## Requirements

### Problem Statement

Traditional banking system usually makes profit sitting between lenders and borrowers. Getting loan from bank is expensive, slow and sometimes impossible(with low credit score).

### Goals

We wanted to solve the issue with blockchain technologies. Our smart-contract based solution on Ethereum blockchain enables parties to lend/borrow money without third-party(banks).

### Stakeholders

There are 3 kinds of actors:

- Borrowers - they borrow money in eth
- Lenders - they lend money in eth
- Smart-contract designers - they take 1%(this may change) profit of lender from successful deal when borrower pays back with interest.

### Restrictions/Rules

Only registered users(borrowers/lenders) can call certain methods. These types of users are registered by owners of smart-contract.

### Data Structures

We used Solidity's built-in `array`, `mapping` and `enum` data structures. In addition, we created a data structure of type `struct` called *LoanRequest*:
```
struct LoanRequest {
    address lender;
    uint256 amount;
    uint8 interestRate;
    uint8 creditScore;
    LoanStatus status;
}
``` 

### Exceptions

The smart-contract has many exceptions including not only the following(names of exceptions are self-explanatory we hope):
```
NotRegisteredOwner
NotRegisteredBorrower
NotRegisteredLender
DepositCannotBeZero
NotEnoughFunds
NoFundsInDeposit
BurnAddressProhibited
HasActiveLoan
OnlyOwnersAndBorrowersCanAccess
InvalidInterestRate
OnlyOwnersAndLendersCanAccess
```

### User Stories

- Borrowers - borrowers get registered with the help of owners. They will have deposit accounts. Borrowers have limit in amount they can borrow. When borrower borrows money, the user must have 50% of the money in deposit account. This money will be locked until the user pays back the loan with interest. If user does not return money on time, and lender decides to take money, the locked money of borrower will be transferred to lender. A borrower user can deposit ether into their deposit account at any time, any amount. Once the user reaches targeted amount, he/she makes loan request. When loan request is made deposit money is locked. The user may cancel the loan request(locked money is released) and take out money from deposit.
- Lenders - they have access to the list of loan requests. They may choose any loan request they like and fulfill that request. When lender fulfills a request, money will be transferred to smart-contract balance and then from smart-contract balance to borrower balance. This process changes status of loan request and it permanently locks the deposit balance of borrower. Once loan request is fulfilled, borrower can not cancel it and take locked money, instead, borrower is supposed to pay back his/her debt with agreed interest rate.
- Smart-contract designers - there are multiple owner users. Owner type of user can add borrwers, lenders to the system. Call payout method to take profit ethers from smart-contract balance. Profit ethers will be collected from each successfull payback of debt with interest by borrower. For example, a borrower borrowed 2 ethers putting into 1 ether as a warranty deposit for 1 month with 10% interest rate. After a month he returns 2.2 ethers, and gets his deposited 1 ether back. Lender made 0.18 ethers profit(9%), and 0.02 ehthers(1%) goes to smart-contract profit balance.
  

#

## Architecture

### Project Description

**TODO**

### Overview

Our smart-contract based solution on Ethereum blockchain enables parties to lend/borrow money without third-party(banks). The system makes profit out of each successful borrow-return process after facilitating simple escrow like service for lenders and borrowers.

### Data

**TODO**

### Functions

**TODO**

### System Diagram

![](./assets/system-diagram.jpg)

### Flow Diagram

![](./assets/flow-diagram.jpg)

### Tech-stack

Smart-contract in Solidity language, Ethereum blockchain

#

## Project Plan

The total time estimate for this project is approximately 2 weeks (17 days)

### Task breakdown

Below is the breakdown of all tasks including the assignment and time estimation for each task.
![](./assets/task-management.png)

### Gantt Chart

![](./assets/gantt-chart.png)
