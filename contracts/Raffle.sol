// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Raffle {
    // error code for not enough eth set
    //best practice contract_name + double underscore + error code name
    error Raffle__NotEnoughETHEntered();

    //entrance fee for the lottery
    uint256 private immutable i_entranceFee; // should be private cause it involves in payment

    //prefix i to denote the immutable
    //immutable because it reduces the gas price
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() payable {
        //require (msg.value > i_entranceFee,"Not enough ETH!")
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
    }

    // function pickRandomWinner(){
    // }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
