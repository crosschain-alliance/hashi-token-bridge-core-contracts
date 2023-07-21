pragma solidity ^0.8.19;

import {SJMessage} from "./ISJMessage.sol";

/**
 * @title ISJReceiver
 * @author Saje Function
 *
 * @notice
 */
interface ISJReceiver {
    event MessageProcessed(SJMessage);

    function getMessageHash(SJMessage memory message) external pure returns (bytes32);

    function onMessage(SJMessage calldata message) external;
}
