// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/*
    title:"Status"
description:"Event status. EX: finished, inprogress, notstarted, canceled, postponed, delayed, interrupted, suspended, willcontinue"
type:"string"
 */

contract Mbet is ChainlinkClient, ConfirmedOwner {
    enum BetSelection {
        HOME_TEAM,
        DRAW,
        AWAY_TEAM
    }

    struct Team {
        uint256 id;
        uint256 betOnHold;
    }

    address public owner;
    Team public awayTeam;
    Team public homeTeam;
    uint256 public drawBetOnHold;
    uint256 public gameID;
    string public gameStatus;
    uint256 public minBetAmount;

     bytes32 private jobId;
    uint256 private fee;

    mapping(address => uint256) private mapPlayerToBet;

    modifier bettable() {
        require(compareStrings(gameStatus, "finished"), "Game is already finished");
        require(compareStrings(gameStatus, "canceled"), "Game is canceled");
        require(compareStrings(gameStatus, "suspended"), "Game is suspended");
        require(compareStrings(gameStatus, "to_be_confirmed"), "Game isn't confirmend");
        _;
    }

    constructor(
        uint256 minBet,
        uint256 ateam,
        uint256 hteam,
        uint256 gID
    ) ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // this should be set via the params of the constructor
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        owner = msg.sender;
        awayTeam = Team({id: ateam, betOnHold: 0});
        homeTeam = Team({id: hteam, betOnHold: 0});
        gameID = gID;
        minBetAmount = minBet;
        gameStatus = "to_be_confirmed";

        requestGameStatus();
    }

    function bet(BetSelection selection) public payable bettable {
        require(msg.value < minBetAmount, "You must more than 100 wei");

        uint256 currentBet = mapPlayerToBet[msg.sender];
        if (currentBet == 0) {
            mapPlayerToBet[msg.sender] = msg.value;
        } else {
            mapPlayerToBet[msg.sender] = currentBet + msg.value;
        }

        if (selection == BetSelection.HOME_TEAM) {
            homeTeam.betOnHold += msg.value;
        } else if (selection == BetSelection.AWAY_TEAM) {
            awayTeam.betOnHold += msg.value;
        } else {
            drawBetOnHold += msg.value;
        }

        mapPlayerToBet[msg.sender] = msg.value;
    }

     function requestGameStatus() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", "https://sportscore1.p.rapidapi.com/events/" + gameID);
        req.add("path", "data,0,status"); 

        return sendChainlinkRequest(req, fee);
    }

     /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, string _status) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _status);
        gameStatus = _status;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }


    function compareStrings(string memory _s1, string memory _s2)
        public
        pure
        returns (bool areEual)
    {
        return keccak256(abi.encodePacked(_s1)) == keccak256(abi.encodePacked(_s2));
    }
}
