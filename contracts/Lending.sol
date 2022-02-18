//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lending {
    //#region State variables
    mapping(address => bool) private owners;
    mapping(address => uint256) private deposits;

    //#region

    constructor() {
        // TODO this should be replaced with our address
        // so that we're added as the contract owners (TBD)
        owners[address(uint160(bytes20("0x1")))] = true;
        owners[address(uint160(bytes20("0x2")))] = true;
        owners[address(uint160(bytes20("0x3")))] = true;
        owners[address(uint160(bytes20("0x4")))] = true;
    }

    //#region Modifiers
    modifier onlyOwners() {
        require(owners[msg.sender], "Only for owners!");
        _;
    }

    //#region

    // we use external to save gas because we know this function can only be called externally
    function depositMoney() external payable {
        require(msg.value > 0, "Deposit must be greater than 0!");
        require(msg.sender.balance >= msg.value, "Not enough funds!");

        deposits[msg.sender] += msg.value;
    }

    function getDepositBalance() external view returns (uint256) {
        return deposits[msg.sender];
    }

    function withdrawDeposit() external payable {
        require(deposits[msg.sender] > 0, "You don't have any deposit!");

        uint256 _amount = deposits[msg.sender];
        deposits[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to withdraw");
    }
}
