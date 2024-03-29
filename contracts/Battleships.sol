//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

contract Battleships is Nft("","Battleships","BTS") {
    //gas optimization for game interactions
    error NotOwnedOrApprovedFor(uint tokenId);
    function requireOwnsOrIsApprovedForList(address addr, uint[] calldata tokenIds) external view {
        for(uint i = 0; i < tokenIds.length; i++) {
            if(!(ownerOf(tokenIds[i]) == addr || isApprovedForAll(ownerOf(tokenIds[i]), addr) || getApproved(tokenIds[i]) == addr)) {
                revert NotOwnedOrApprovedFor(tokenIds[i]);
            }
        }
    }
}