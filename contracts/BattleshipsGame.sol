//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BattleToken.sol";
import "./IBattleshipsTracker.sol";
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

contract Battleships is AccessControl, Nft("uri", "Battleships", "BTS") {

    struct PositionProof {
        uint shipId;
        uint x;
        uint y;
        string salt;
    }

    struct ShipOption {
        uint yield;
        uint width;
        uint height;
        uint bombSlots;
        uint bombCooldown;
        UpgradePath[] upgradePaths;
    }

    struct UpgradePath {
        uint price;
        uint yieldIncrease;
        uint bombSlotIncrease;
    }

    struct BombSlot {
        bool taken;
        uint takenAt;
    }

    struct Location {
        uint bombedAt;
        uint bombedBy;
    }

    struct Ship {
        bytes32 positionHash;
        uint upgradeCount;
        uint shipOption;
        uint lastPlaced;
        uint siphonedTo;
        uint siphonedSince;
        uint owed;
        BombSlot[] bombSlots;
    }

    struct Config {
        uint xMax;
        uint yMax;
        uint bombTime;
        uint bombCooldown;
        uint bombPrice;
        ShipOption[] shipOptions;
    }

    BattleToken public battleToken;

    Config public config;
    mapping(uint => Ship) public ships;
    mapping(uint => mapping(uint => Location)) public locations;

    constructor(BattleToken newBattleToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        battleToken = newBattleToken;
    }

    //Be careful
    function setConfig(Config memory newConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        config.xMax = newConfig.xMax;
        config.yMax = newConfig.yMax;
        config.bombTime = newConfig.bombTime;
        config.bombCooldown = newConfig.bombCooldown;
        config.bombPrice = newConfig.bombPrice;
        delete config.shipOptions;
        for (uint i = 0; i < newConfig.shipOptions.length; i++) {
            ShipOption storage shipOption = config.shipOptions.push();
            shipOption.yield = newConfig.shipOptions[i].yield;
            shipOption.width = newConfig.shipOptions[i].width;
            shipOption.height = newConfig.shipOptions[i].height;
            shipOption.bombSlots = newConfig.shipOptions[i].bombSlots;
            shipOption.bombCooldown = newConfig.shipOptions[i].bombCooldown;
            for (uint j = 0; j < newConfig.shipOptions[i].upgradePaths.length; j++) {
                UpgradePath storage upgradePath = shipOption.upgradePaths.push();
                upgradePath.price = newConfig.shipOptions[i].upgradePaths[j].price;
                upgradePath.yieldIncrease = newConfig.shipOptions[i].upgradePaths[j].yieldIncrease;
                upgradePath.bombSlotIncrease = newConfig.shipOptions[i].upgradePaths[j].bombSlotIncrease;
            }
        }
    }

    function _claimableCalculation(uint shipOption, uint lastPlaced, uint siphonedTo, uint siphonedSince) private view returns(uint) {

    }

    function _verifyPosition(PositionProof memory proof) private view returns (bool) {
        return keccak256(abi.encodePacked(proof.x, proof.y, proof.salt)) == ships[proof.shipId].positionHash;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(Nft, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}