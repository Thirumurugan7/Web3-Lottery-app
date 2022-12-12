// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETHEntered();
    // error code for not enough eth set
    //best practice contract_name + double underscore + error code name

    //entrance fee for the lottery
    uint256 private immutable i_entranceFee; // should be private cause it involves in payment

    address payable[] private s_players; // should be private cause it involves in payment

    /* Events */

    event RaffleEnter(address indexed player);

    //every time the player wins we need to pay for them
    //prefix i to denote the immutable
    //immutable because it reduces the gas price
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
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
        //events are used when we update a dynamic object like map or array

        emit RaffleEnter(msg.sender);
    }

    function requestRandomWinner() external {
        //external is cheaper than public
        //steps->1request the random number
        //2.Once weget it do something with it
        //3.
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}

    /* view / pure functions */
    // to retreive the entrance fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
