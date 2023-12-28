// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.19;

import {IYaho} from "../interfaces/hashi/IYaho.sol";
import {Message} from "../interfaces/hashi/IMessageDispatcher.sol";

error CallFailed();

contract MockYaru {
    address public sender;

    function executeMessage(Message calldata message, address sender_) external {
        sender = sender_;
        (bool success, ) = address(message.to).call(message.data);
        if (!success) revert CallFailed();
        delete sender;
    }
}
