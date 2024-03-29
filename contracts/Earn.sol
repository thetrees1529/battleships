//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "./Token.sol";
import "./Battleships.sol";
import "./LockedBattleToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Earn is AccessControl {

    struct EarnInfo {
        //config
        bool initialised;
        uint lockPercentage;
        uint earnRate;
        uint earnCap;

        //penalties
        bool penaltyInEffect;
        uint penaltyLeft;

        //require claim to be approved after every claim
        bool claimApproved;
        uint claimApprovedAt;

        //historical
        uint totalEarned;
        uint calculateFrom;

        //current
        uint owedUnlocked;
        uint owedLocked;
    }

    Token public battleToken;
    Battleships public battleships;
    LockedBattleToken public lockedBattleToken;

    mapping(uint => EarnInfo) private _earnInfos;

    constructor(Token newBattleToken, Battleships newBattleships, LockedBattleToken newLockedBattleToken) {

        battleToken = newBattleToken;
        battleships = newBattleships;
        lockedBattleToken = newLockedBattleToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    function getInitialiseds(uint[] calldata tokenIds) external view returns(bool[] memory initialiseds) {

        initialiseds = new bool[](tokenIds.length);

        for(uint i = 0; i < tokenIds.length; i++) {
            initialiseds[i] = _earnInfos[tokenIds[i]].initialised;
        }

    }

    function getPotentiallyClaimables(uint[] calldata tokenIds) external view returns(uint[] memory unlockeds, uint[] memory lockeds) {

        unlockeds = new uint[](tokenIds.length);
        lockeds = new uint[](tokenIds.length);

        for(uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _getEarnInfo(tokenId);
            (, , unlockeds[i]) = _claimCalculation(_earnInfo.calculateFrom, block.timestamp, _earnInfo.penaltyLeft, _earnInfo.earnRate, _earnInfo.earnCap, _earnInfo.totalEarned, _earnInfo.lockPercentage);
            lockeds[i] = _earnInfo.owedLocked;
        }

    }

    function initialise(uint[] calldata tokenIds, uint[] calldata lockPercentages, uint[] calldata earnRates, uint[] calldata earnCaps) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            _initialise(tokenIds[i], lockPercentages[i], earnRates[i], earnCaps[i]);
        }

    }

    function addPenalties(uint[] calldata tokenIds, uint[] calldata penalties) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _getEarnInfo(tokenId);
            if(!_earnInfo.penaltyInEffect) _earnInfo.penaltyInEffect = true;
            _earnInfo.penaltyLeft += penalties[i];
        }

    }

    function approveClaims(uint[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _getEarnInfo(tokenId);
            if(!_earnInfo.claimApproved) _earnInfo.claimApproved = true;
            _earnInfo.claimApprovedAt = block.timestamp;
        }

    }

    function updateEarnRates(uint[] calldata tokenIds, uint[] calldata earnRates) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _update(tokenId);
            _earnInfo.earnRate = earnRates[i];
        }

    }

    function updateEarnCaps(uint[] calldata tokenIds, uint[] calldata earnCaps) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _update(tokenId);
            _earnInfo.earnCap = earnCaps[i];
        }

    }

    function updateLockPercentages(uint[] calldata tokenIds, uint[] calldata lockPercentages) external onlyRole(DEFAULT_ADMIN_ROLE) {

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _update(tokenId);
            _earnInfo.lockPercentage = lockPercentages[i];
        }

    }

    function claim(uint[] calldata tokenIds) external {

        battleships.requireOwnsOrIsApprovedForList(msg.sender, tokenIds);

        uint toMint;

        for(uint i = 0; i < tokenIds.length; i++) {

            uint tokenId = tokenIds[i];
            EarnInfo storage _earnInfo = _getEarnInfo(tokenId);
            require(_earnInfo.claimApproved, "Claim not approved");
            _earnInfo.claimApproved = false;

            (uint penaltyLeft, uint locked, uint unlocked) = _claimCalculation(_earnInfo.calculateFrom, block.timestamp, _earnInfo.penaltyLeft, _earnInfo.earnRate, _earnInfo.earnCap, _earnInfo.totalEarned, _earnInfo.lockPercentage);
            _earnInfo.penaltyLeft = penaltyLeft;
            _earnInfo.totalEarned += locked + unlocked;

            toMint += unlocked + _earnInfo.owedUnlocked;
            lockedBattleToken.lock(tokenIds[i], locked + _earnInfo.owedLocked);

            delete _earnInfo.owedUnlocked;
            delete _earnInfo.owedLocked;

        }

        battleToken.mint(msg.sender, toMint);

    }

    function _initialise(uint tokenId, uint lockPercentage, uint earnRate, uint earnCap) private {

        EarnInfo storage _earnInfo = _earnInfos[tokenId];
        require(!_earnInfo.initialised, "Already initialised");
        _earnInfo.initialised = true;
        _earnInfo.earnRate = earnRate;
        _earnInfo.calculateFrom = block.timestamp;
        _earnInfo.lockPercentage = lockPercentage;
        _earnInfo.earnCap = earnCap;

    }

    function _claimCalculation(uint calculateFrom, uint calculateTo, uint penalty, uint earnRate, uint earnCap, uint totalEarned, uint lockPercentage) private pure returns(uint penaltyLeft, uint locked, uint unlocked) {
        
        uint potentialTimeEarning = calculateTo - calculateFrom;
        uint timeEarning;
        if(penalty > potentialTimeEarning) {
            penaltyLeft = penalty - potentialTimeEarning;
        } else {
            timeEarning = potentialTimeEarning - penalty;
        }
        uint earnable = earnCap - totalEarned;
        uint potentiallyEarned = timeEarning * earnRate;
        uint earned = potentiallyEarned > earnable ? earnable : potentiallyEarned;
        locked = ((earned * lockPercentage) / 100);
        unlocked = earned - locked;

    }

    function _getEarnInfo(uint tokenId) private view returns(EarnInfo storage) {

        EarnInfo storage _earnInfo = _earnInfos[tokenId];
        require(_earnInfo.initialised, "Not initialised");
        return _earnInfo;

    }

    function _update(uint tokenId) private returns(EarnInfo storage _earnInfo) {

        _earnInfo = _getEarnInfo(tokenId);

        (uint penaltyLeft, uint locked, uint unlocked) = _claimCalculation(_earnInfo.calculateFrom, _earnInfo.claimApprovedAt, _earnInfo.penaltyLeft, _earnInfo.earnRate, _earnInfo.earnCap, _earnInfo.totalEarned, _earnInfo.lockPercentage);

        _earnInfo.calculateFrom = _earnInfo.claimApprovedAt;
        _earnInfo.totalEarned += locked + unlocked;
        _earnInfo.owedLocked += locked;
        _earnInfo.owedUnlocked += unlocked;
        _earnInfo.penaltyLeft = penaltyLeft;

    }

}