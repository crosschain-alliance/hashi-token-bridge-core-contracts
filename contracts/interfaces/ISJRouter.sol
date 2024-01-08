pragma solidity ^0.8.19;

import {SJMessage} from "./ISJMessage.sol";

interface ISJRouter {
    error NotYaru(address caller, address expectedYaru);
    error NotOppositeSJRouter(address sender, address expectedSJRouter);
    error MessageAlreadyProcessed(SJMessage message);
    error TokenNotCreated(address token);
    error MessageAlreadyAdvanced(SJMessage message);
    error InvalidFastLaneFeeAmount(uint256 fastLaneFeeAmount);
    error InvalidXtransfer();

    event MessageDispatched(SJMessage);
    event MessageProcessed(SJMessage);
    event MessageAdvanced(SJMessage);

    function advanceMessage(SJMessage calldata message) external;

    function xTransfer(
        uint256 destinationChainId,
        address receiver,
        address underlyingTokenAddress,
        string calldata underlyingTokenName,
        string calldata underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        uint256 amount,
        uint256 fastLaneFeeAmount
    ) external;

    function getMessageId(SJMessage memory message) external pure returns (bytes32);

    function onMessage(SJMessage calldata message) external;

    function setOppositeSjRouter(address sourceSjRouter_) external;
}
