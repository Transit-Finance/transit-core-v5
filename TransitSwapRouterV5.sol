// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UniswapV2Router.sol";
import "./UniswapV3Router.sol";
import "./AggregateRouter.sol";
import "./CrossRouter.sol";
import "./libs/Ownable.sol";

contract TransitSwapRouterV5 is UniswapV2Router, UniswapV3Router, AggregateRouter, CrossRouter, Ownable  {

    constructor() Ownable(msg.sender) {

    }

    function changeFee(bool[] memory isAggregate, uint256[] memory newRate) external onlyExecutor {
        updateFee(isAggregate, newRate);
    }

    function changeTransitProxy(address aggregator, address signer) external onlyExecutor {
        if (aggregator != address(0)) {
            updateAggregateBridge(aggregator);
        }
        if (signer != address(0)) {
            updateSigner(signer);
        }
    }

    function changeAllowed(address[] calldata crossCallers, address[] calldata wrappedTokens) public onlyExecutor {
        if(crossCallers.length != 0){
            updateCrossCallerAllowed(crossCallers);
        }
        if(wrappedTokens.length != 0) {
            updateWrappedAllowed(wrappedTokens);
        }
    }

    function changeUniswapV3FactoryAllowed(uint[] calldata poolIndex, address[] calldata factories, bytes[] calldata initCodeHash) public onlyExecutor {
        require(poolIndex.length == initCodeHash.length, "invalid data");
        require(factories.length == initCodeHash.length, "invalid data");
        updateUniswapV3FactoryAllowed(poolIndex, factories, initCodeHash);
    }

    function changePause(bool paused) external onlyExecutor {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for (uint index; index < tokens.length; index++) {
            uint amount;
            if (TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}