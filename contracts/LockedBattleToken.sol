//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LockedBattleToken is AccessControl {
    event Locked(uint id, uint amount);
    event Unlocked(uint id, uint amount);
    mapping(uint => uint) public locked;
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function lock(uint id, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        locked[id] += amount;
        emit Locked(id, amount);
    }
    function unlock(uint id, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        locked[id] -= amount;
        emit Unlocked(id, amount);
    }
}