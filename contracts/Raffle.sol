// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
error Raffle__NotEnoughETHEntered();
error Raffle__transferFail();

contract Raffle is VRFConsumerBaseV2 {
    // error code for not enough eth set
    //best practice contract_name + double underscore + error code name

    //entrance fee for the lottery
    uint256 private immutable i_entranceFee; // should be private cause it involves in payment

    address payable[] private s_players; // should be private cause it involves in payment

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    bytes32 private immutable i_gasLane;

    uint64 private immutable i_subscriptionId;

    uint16 private constant REQUEST_CONFIRMATION = 3;

    uint32 private immutable i_callbackGasLimit;

    uint32 private constant NUM_WORDS = 1;

    //lottery variables

    address private s_recentWinner;
    /* Events */

    event RaffleEnter(address indexed player);

    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner); //to keep track of previous winners

    //every time the player wins we need to pay for them
    //prefix i to denote the immutable
    //immutable because it reduces the gas price
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
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

    function requestRandomWords() external {
        //external is cheaper than public
        //steps->1request the random number
        //2.Once weget it do something with it

        uint256 requestID = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //max gas price willing to pay for a  request in wei
            i_subscriptionId, // chain;inksubscription id
            REQUEST_CONFIRMATION,
            i_callbackGasLimit, //the limit of how much gas to use for the callback request to contract fulfillRandomWords
            NUM_WORDS //how many random number we want
        );

        emit RequestedRaffleWinner(requestID);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); //sending all the money from this contract to the winner
        if (!success) {
            revert Raffle__transferFail();
        }
        emit WinnerPicked(recentWinner);
    }

    /* view / pure functions */
    // to retreive the entrance fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
