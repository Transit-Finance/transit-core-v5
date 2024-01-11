// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account, PausedFlag flag);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account, PausedFlag flag);

    mapping(PausedFlag => bool) private _paused;

    enum PausedFlag {executeAggregate, executeV2Swap, executeV3Swap, cross}

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(PausedFlag flag) {
        _requireNotPaused(flag);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(PausedFlag flag) {
        _requirePaused(flag);
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(PausedFlag flag) public view virtual returns (bool) {
        return _paused[flag];
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused(PausedFlag flag) internal view virtual {
        require(!paused(flag), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused(PausedFlag flag) internal view virtual {
        require(paused(flag), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(PausedFlag flag) internal virtual whenNotPaused(flag) {
        _paused[flag] = true;
        emit Paused(msg.sender, flag);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(PausedFlag flag) internal virtual whenPaused(flag) {
        _paused[flag] = false;
        emit Unpaused(msg.sender, flag);
    }

    function pausedOverAll() public view virtual returns (bool executeAggregate, bool executeV2Swap, bool executeV3Swap, bool cross) {
        executeAggregate = _paused[PausedFlag.executeAggregate];
        executeV2Swap = _paused[PausedFlag.executeV2Swap];
        executeV3Swap = _paused[PausedFlag.executeV3Swap];
        cross = _paused[PausedFlag.cross];
    }
}