pragma solidity ^0.8.19;

import {SJMessage} from "./ISJMessage.sol";

/**
 * @title ISJDispatcher
 * @author Saje Function
 *
 * @notice
 */
interface ISJDispatcher {
    event MessageDispatched(SJMessage);

    function dispatch(
        uint256 destinationChainId,
        address sourceTokenAddress,
        string calldata sourceTokenName,
        string calldata sourceTokenSymbol,
        uint8 sourceTokenDecimals,
        uint256 sourceTokenChainId,
        uint256 sourceTokenAmount,
        address receiver
    ) external;
}
