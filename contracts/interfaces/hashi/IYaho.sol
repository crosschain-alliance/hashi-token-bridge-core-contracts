// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import {IMessageRelay} from "./IMessageRelay.sol";
import {IMessageDispatcher, Message} from "./IMessageDispatcher.sol";

interface IYaho is IMessageDispatcher {
    function dispatchMessages(Message[] memory messages) external payable returns (bytes32[] memory);

    function relayMessagesToAdapters(
        uint256[] memory messageIds,
        address[] memory sourceAdapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory);

    function dispatchMessagesToAdapters(
        Message[] memory messages,
        address[] memory sourceAdapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory messageIds, bytes32[] memory);
}
