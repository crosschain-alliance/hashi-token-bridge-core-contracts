pragma solidity ^0.8.19;

import {IOFTV2} from "@lz/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";

/**
 * @title ISJToken
 * @author Saje Function
 *
 * @notice
 */
interface ISJToken is IOFTV2 {
    error NotNative();

    function xTransfer(uint256 destinationChainId, address to, uint256 amount) external payable;

    function unwrap(address to, uint256 amount) external;
}
