// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
    title:"Status"
description:"Event status. EX: finished, inprogress, notstarted, canceled, postponed, delayed, interrupted, suspended, willcontinue"
type:"string"
 */

contract Mbet {
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
    mapping(address => uint256) mapPlayerToBet;

    modifier bettable() {
        require(compareStrings(gameStatus, "finished"), "Game is already finished");
        require(compareStrings(gameStatus, "canceled"), "Game is canceled");
        require(compareStrings(gameStatus, "suspended"), "Game is suspended");
        _;
    }

    constructor(
        uint256 ateam,
        uint256 hteam,
        uint256 gID
    ) {
        owner = msg.sender;
        awayTeam = Team({id: ateam, betOnHold: 0});
        homeTeam = Team({id: hteam, betOnHold: 0});
        gameID = gID;
        gameStatus = "to_be_confirmed";
    }

    function bet(BetSelection selection) public payable bettable {
        require(msg.value < 100 wei, "You must more than 100 wei");

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

    function compareStrings(string memory _s1, string memory _s2)
        public
        pure
        returns (bool areEual)
    {
        return keccak256(abi.encodePacked(_s1)) == keccak256(abi.encodePacked(_s2));
    }
}
