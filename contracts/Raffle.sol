// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Raffle {
    // error code for not enough eth set
    //best practice contract_name + double underscore + error code name
    error Raffle__NotEnoughETHEntered();

    //entrance fee for the lottery
    uint256 private immutable i_entranceFee; // should be private cause it involves in payment

    address payable[] private s_players; // should be private cause it involves in payment

    //every time the player wins we need to pay for them
    //prefix i to denote the immutable
    //immutable because it reduces the gas price
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    //to enter the raffle

    function enterRaffle() public payable {
        //require (msg.value > i_entranceFee,"Not enough ETH!")
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        //once the player enters the raffle we push them into the s_players array
        s_players.push(payable(msg.sender));
    }

    // function pickRandomWinner(){
    // }
    // to retreive the entrance fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
