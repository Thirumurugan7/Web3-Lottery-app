// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__transferFail();
error Raffle__NotOpened();
error Raffle__UpkeepNoNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/** @title Raffle Contract
 * @author Thirumrugan Sivalingam
 * @notice This contract is for creating an untempertable decentralised smart contract
 * @dev This implements chainlink VRF and V2 and Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } // CREATING NEW TYPE

    // error code for not enough eth set
    //best practice contract_name + double underscore + error code name
    /** state variables */
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
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    /* Events */

    event RaffleEnter(address indexed player);

    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner); //to keep track of previous winners

    //every time the player wins we need to pay for them
    //prefix i to denote the immutable
    //immutable because it reduces the gas price
    constructor(
        address vrfCoordinatorV2, //contract address - need to deploy some mock for this
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp; //to keep track og last time stamp
        //timestamp is a already existing funcion in solidity

        i_interval = interval; //the time we wait for lottery transaction
    }

    //to enter the raffle

    function enterRaffle() public payable {
        //require (msg.value > i_entranceFee,"Not enough ETH!")
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpened();
        }
        //once the player enters the raffle we push them into the s_players array
        s_players.push(payable(msg.sender));
        //events are used when we update a dynamic object like map or array

        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they lookl for the upkeepNeeded to return true
     * the following should be true inorder to return true
     * 1.our team interval shold be passed
     * 2.the lottery should have at least 1 player, and have some ETH
     * 3.Our subscriptions is funded with LINK
     * 4.The lottery should be in an "OPEN" state
     *  */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* perfromData*/)
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //external is cheaper than public
        //steps->1request the random number
        //2.Once weget it do something with it

        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNoNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
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
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // reseting players array
        s_lastTimeStamp = block.timestamp;
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

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmation() public pure returns (uint256) {
        return REQUEST_CONFIRMATION;
    }
}
