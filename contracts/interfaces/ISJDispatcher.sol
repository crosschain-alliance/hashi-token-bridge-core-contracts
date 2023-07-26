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
        address underlyingTokenAddress,
        string calldata underlyingTokenName,
        string calldata underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        uint256 amount,
        address receiver
    ) external;
}
