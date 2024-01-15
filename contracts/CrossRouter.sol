// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract CrossRouter is BaseCore {

    using SafeMath for uint256;

    constructor() {}

    function cross(CrossDescription calldata desc) external payable nonReentrant whenNotPaused(FunctionFlag.cross) {
        require(desc.calls.length > 0, "data should be not zero");
        require(desc.amount > 0, "amount should be greater than 0");
        require(_cross_caller_allowed[desc.caller], "invalid caller");
        
        uint256 swapAmount = executeFunds(FunctionFlag.cross, desc.srcToken, desc.wrappedToken, desc.caller, desc.amount, desc.fee, desc.signature);

        {
            (bool success, bytes memory result) = desc.caller.call{value:swapAmount}(desc.calls);
            if (!success) {
                revert(RevertReasonParser.parse(result, "TransitCrossV5:"));
            }
            TransferHelper.safeApprove(desc.srcToken, desc.caller, 0);
        }

        _emitTransit(desc.srcToken, desc.dstToken, desc.dstReceiver, desc.amount, 0, desc.toChain, desc.channel);
    } 
}