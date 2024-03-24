//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
interface IBattleShipsTracker {
    function handleBombDropped(uint shipId, uint x, uint y) external;
    function handleBombStrike(uint shipIdBomber, uint shipIdBombee) external;
}