// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

enum GasMode {
    VOID,
    CLAIMABLE
}

interface IBlast{
    function configureAutomaticYield() external;
    function configureClaimableGas() external;
    function configureGovernor(address _governor) external;
    
}