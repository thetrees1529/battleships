//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Battleships.sol";

contract Positions {

    struct Position {

        uint count;

        uint setAt;
        bytes32 positionHash;

        bool isRevealed;
        uint revealedAt;
        uint revealedX;
        uint revealedY;

    }

    struct PositionInfo {
        uint positionCount;
        bool positionIsRevealed;
    }

    Battleships public battleships;
    mapping(uint => Position) private _positions;

    constructor(Battleships newBattleships) {
        battleships = newBattleships;
    }

    function getPositionCount(uint tokenId) external view returns(uint) {
        return _positions[tokenId].count;
    }

    function getPositionInfo(uint tokenId) external view returns(uint setAt, bool positionIsRevealed, bytes32 positionHash) {
        Position storage _position = _positions[tokenId];
        require(_position.count > 0, "Position not yet set");
        return (_position.setAt, _position.isRevealed, _position.positionHash);
    }

    function getRevealedPosition(uint tokenId) external view returns(uint revealedAt, uint x, uint y) {
        Position storage _position = _positions[tokenId];
        require(_position.isRevealed, "Position not revealed");
        return (_position.revealedAt, _position.revealedX, _position.revealedY);
    }

    function setPositions(uint[] memory tokenIds, bytes32[] memory positionHashes) external {

        battleships.requireOwnsOrIsApprovedForList(msg.sender, tokenIds);

        for(uint i = 0; i < tokenIds.length; i++) {
            _setPosition(tokenIds[i], positionHashes[i]);
        }

    }

    function revealPositions(uint[] memory tokenIds, uint[] memory revealedXs, uint[] memory revealedYs, string[] memory salts) public {
        
        battleships.requireOwnsOrIsApprovedForList(msg.sender, tokenIds);
        
        for(uint i = 0; i < tokenIds.length; i++) {
            _revealPosition(tokenIds[i], revealedXs[i], revealedYs[i], salts[i]);
        }

    }


    function _revealPosition(uint tokenId, uint revealedX, uint revealedY, string memory salt) private {

        require(!_positions[tokenId].isRevealed, "Position already revealed");
        require(_positions[tokenId].positionHash == keccak256(abi.encodePacked(tokenId, revealedX, revealedY, salt)), "Invalid proof");
        
        _positions[tokenId].isRevealed = true;
        _positions[tokenId].revealedAt = block.timestamp;
        _positions[tokenId].revealedX = revealedX;
        _positions[tokenId].revealedY = revealedY;

    }

    function _setPosition(uint tokenId, bytes32 positionHash) private {

        _positions[tokenId].count++;
        _positions[tokenId].positionHash = positionHash;
        _positions[tokenId].setAt = block.timestamp;

        if(_positions[tokenId].isRevealed) _positions[tokenId].isRevealed = false;

    }

}