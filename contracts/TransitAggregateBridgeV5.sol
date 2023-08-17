// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libs/Ownable.sol";
import "./libs/TransferHelper.sol";
import "./libs/RevertReasonParser.sol";
import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";

contract TransitAggregateBridgeV5 is Ownable {
    
    using SafeMath for uint256;

    enum NeedTransferFlag {unnecessary, native, token}

    struct AggregateDescription {
        address dstToken;
        address receiver;
        uint[] amounts;
        uint8[] needTransfer;
        address[] callers;
        address[] approveProxy;
        bytes[] calls;
    }

    struct CallbytesDescription {
        address srcToken;
        bytes calldatas;
    }

    address private _transit_router;
    bool private _allowed_enabled;
    mapping(address => bool) private _caller_allowed;
    mapping(address => mapping(address => bool)) private _approves;

    event Receipt(address from, uint256 amount);
    event ChangeCallerAllowed(address[] callers);
    event ChangeAllowedEnabled(bool _allowed_enabled);
    event ChangeTransitRouter(address indexed previousRouter, address indexed newRouter);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    
    constructor (address executor) Ownable(executor) {

    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function transitRouter() public view returns (address) {
        return _transit_router;
    }

    function approves(address token, address caller) public view returns (bool) {
        return _approves[token][caller];
    }

    function allowed(address caller) public view returns (bool) {
        return _caller_allowed[caller];
    }

    function allowedEnabled() public view returns (bool) {
        return _allowed_enabled;
    }

    function changeAllowedEnabled() public onlyExecutor {
        _allowed_enabled = !_allowed_enabled;
        emit ChangeAllowedEnabled(_allowed_enabled);
    }

    function changeTransitRouter(address newRouter) public onlyExecutor {
        address oldRouter = _transit_router;
        _transit_router = newRouter;
        emit ChangeTransitRouter(oldRouter, newRouter);
    }
    
    function changeCallerAllowed(address[] calldata callers) public onlyExecutor {
        for (uint i; i < callers.length; i++) {
            _caller_allowed[callers[i]] = !_caller_allowed[callers[i]];
        }
        emit ChangeCallerAllowed(callers);
    }

    function callbytes(CallbytesDescription calldata desc) external payable {
        require(msg.sender == _transit_router, "TransitAggregateBridgeV5: invalid router");
        AggregateDescription memory aggregateDesc = decodeAggregateDesc(desc.calldatas);
        require(aggregateDesc.callers.length == aggregateDesc.calls.length, "TransitAggregateBridgeV5: invalid calls");
        require(aggregateDesc.callers.length == aggregateDesc.needTransfer.length, "TransitAggregateBridgeV5: invalid callers");
        require(aggregateDesc.calls.length == aggregateDesc.amounts.length, "TransitAggregateBridgeV5: invalid amounts");
        require(aggregateDesc.calls.length == aggregateDesc.approveProxy.length, "TransitAggregateBridgeV5: invalid calldatas");
        uint256 callSize = aggregateDesc.callers.length;
        
        for (uint index; index < callSize; index++) {
            uint256 beforeBalance;
            if (_allowed_enabled) {
                require(_caller_allowed[aggregateDesc.callers[index]], "TransitAggregateBridgeV5: invalid caller");
            }
            address approveAddress = aggregateDesc.approveProxy[index] == address(0)? aggregateDesc.callers[index]:aggregateDesc.approveProxy[index];
            bool isApproved = _approves[desc.srcToken][approveAddress];
            bool isToETH;
            if (TransferHelper.isETH(aggregateDesc.dstToken)) {
                isToETH = true;
            }
            if (!isApproved) {
                TransferHelper.safeApprove(desc.srcToken, approveAddress, type(uint).max);
                _approves[desc.srcToken][approveAddress] = true;
            }
            if (!TransferHelper.isETH(desc.srcToken)) {
                require(aggregateDesc.amounts[index] == 0, "TransitAggregateBridgeV5: invalid call.value");
            }
            if (isToETH) {
                beforeBalance = address(this).balance;
            } else {
                beforeBalance = IERC20(aggregateDesc.dstToken).balanceOf(address(this));
            }

            {
                (bool success, bytes memory result) = aggregateDesc.callers[index].call{value:aggregateDesc.amounts[index]}(aggregateDesc.calls[index]);
                if (!success) {
                    revert(RevertReasonParser.parse(result,""));
                }
            }

            if (aggregateDesc.needTransfer[index] == uint8(NeedTransferFlag.native)) {
                TransferHelper.safeTransferETH(aggregateDesc.receiver, address(this).balance.sub(beforeBalance));
            } else if (aggregateDesc.needTransfer[index] == uint8(NeedTransferFlag.token)) {
                uint afterBalance = IERC20(aggregateDesc.dstToken).balanceOf(address(this));
                TransferHelper.safeTransfer(aggregateDesc.dstToken, aggregateDesc.receiver, afterBalance.sub(beforeBalance));
            }
        }
    }

    function decodeAggregateDesc(bytes calldata calldatas) internal pure returns (AggregateDescription memory desc) {
        desc = abi.decode(calldatas, (AggregateDescription));
    }

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for(uint index; index < tokens.length; index++) {
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