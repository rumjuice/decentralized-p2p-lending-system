  

## P2P Lending Smart Contract Solution


### Contributors:

- Ravshan: [LinkedIn](https://www.linkedin.com/in/rmakhmadaliev/) [GitHub](https://github.com/Ravshann)

- Jainam: [LinkedIn](https://www.linkedin.com/in/jainmshah/) [GitHub](https://github.com/naxer-12)

- Hossein: [LinkedIn](https://www.linkedin.com/in/hossein-hesami-ccnsp-ceh-5a565b78/) [GitHub](https://github.com/DarioHesami)

- Ramdhani: [LinkedIn](https://www.linkedin.com/in/ramdhaniharis/) [GitHub](https://github.com/rumjuice)

#
## Requirements

### Problem Statement
Traditional banking system usually makes profit sitting between lenders and borrowers. Getting loan from bank is expensive, slow and sometimes impossible(with low credit score).   
### Goals
We wanted to solve the issue with blockchain technologies. Our smart-contract based solution on Ethereum blockchain enables parties to lend/borrow money without third-party(banks). 
### Stakeholders
There are 3 kinds of actors: 
* Borrowers - they borrow money in eth
* Lenders - they lend money in eth
* Smart-contract designers - they take 1%(this may change) profit of lender from successful deal when borrower pays back with interest.
### Restrictions/Rules
Only registered users(borrowers/lenders) can call certain methods. These types of users are registered by owners of smart-contract. 
### Data Structures
TODO
### Exceptions
TODO
### User Stories
* Borrowers - borrowers get registered with the help of owners. They will have deposit accounts. Borrowers have limit in amount they can borrow. When borrower borrows money, the user must have 50% of the money in deposit account. This money will be locked until the user pays back the loan with interest. If user does not return money on time, and lender decides to take money, the locked money of borrower will be transferred to lender. A borrower user can deposit ether into their deposit account at any time, any amount. Once the user reaches targeted amount, he/she makes loan request. When loan request is made deposit money is locked. The user may cancel the loan request(locked money is released) and take out money from deposit.   
* Lenders - they have access to the list of loan requests. They may choose any loan request they like and fulfill that request. When lender fulfills a request, money will be transferred to smart-contract balance and then from smart-contract balance to borrower balance. This process changes status of loan request and it permanently locks the deposit balance of borrower. Once loan request is fulfilled, borrower can not cancel it and take locked money, instead, borrower is supposed to pay back his/her debt with agreed interest rate. 
* Smart-contract designers - there are multiple owner users. Owner type of user can add borrwers, lenders to the system. Call payout method to take profit ethers from smart-contract balance. Profit ethers will be collected from each successfull payback of debt with interest by borrower. For example, a borrower borrowed 2 ethers putting into 1 ether as a warranty deposit for 1 month with 10% interest rate. After a month he returns 2.2 ethers, and gets his deposited 1 ether back. Lender made 0.18 ethers profit(9%), and 0.02 ehthers(1%) goes to smart-contract profit balance. 
#

## Architecture

### Project Description
TODO
### Overview
TODO
### Data
TODO
### Functions
TODO
### Diagrams
TODO
### Tech-stack
Smart-contract in Solidity language, Ethereum blockchain
#

## Project Plan

### Tasks
TODO
### Time Estimation for Tasks
TODO
### Task assignment
TODO
### Dependencies
TODO
### Time Estimation for Project 
TODO
### Gantt Chart