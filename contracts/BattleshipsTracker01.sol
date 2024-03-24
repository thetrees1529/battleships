//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "./IBattleShipsTracker.sol";

contract BattleshipsTracker01 is IBattleShipsTracker {
    struct ShipStats {
        uint bombsDropped;
        uint bombsReceived;
        uint shipsDestroyed;
    }
    mapping(uint => ShipStats) public shipStats;
    mapping(uint => mapping(uint => uint)) public bombStrikeCounts;
    function handleBombDropped(uint shipId, uint x, uint y) external override {
        shipStats[shipId].bombsDropped++;
        bombStrikeCounts[x][y]++;
    }
    function handleBombStrike(uint shipIdBomber, uint shipIdBombee) external override {
        shipStats[shipIdBomber].shipsDestroyed++;
        shipStats[shipIdBombee].bombsReceived++;
    }
}