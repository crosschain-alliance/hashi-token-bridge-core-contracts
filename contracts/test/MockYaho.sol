// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.19;

import {IYaho} from "../interfaces/hashi/IYaho.sol";
import {Message} from "../interfaces/hashi/IMessageDispatcher.sol";

contract MockYaho is IYaho {
    // NOTE: just for testing
    event DispatchedMessage(Message message);

    function dispatchMessages(Message[] memory messages) external payable returns (bytes32[] memory) {}

    function relayMessagesToAdapters(
        uint256[] memory messageIds,
        address[] memory adapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory) {}

    function dispatchMessagesToAdapters(
        Message[] memory messages,
        address[] memory sourceAdapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory messageIds, bytes32[] memory) {
        for (uint256 i = 0; i < messages.length; i++) {
            emit DispatchedMessage(messages[i]);
        }
    }
}
