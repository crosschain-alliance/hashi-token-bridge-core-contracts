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

    /**
     * @notice Advance a message on the Fastlane
     * @param message The Hashi Token Bridge message
     */
    function advanceMessage(SJMessage calldata message) external;

    /**
     * @notice Instruct an cross chain transfer
     * @dev This function operates effectively only when the 'xtokens' on both the source and destination chains share identical variables:
     *      'tokenCreator', 'tokenName', and 'tokenSymbol'. To enhance flexibility and overcome this limitation,
     *      the 'XERC20Factory._deployXERC20' should be modified to include an option for specifying an additional 'bytes32' component within the 'salt'.
     *      This change would allow for greater adaptability in the deployment process.
     * @param destinationChainId The destination chain id
     * @param to The receiver address
     * @param amount The amount to transfer
     * @param fastLaneFeeAmount The maximum fee paid to a mm on fastlane
     * @param tokenCreator The token creator address
     * @param tokenName The token name
     * @param tokenSymbol The token symbol
     */
    function xTransfer(
        uint256 destinationChainId,
        address to,
        uint256 amount,
        uint256 fastLaneFeeAmount,
        address tokenCreator,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external;

    function getMessageId(SJMessage memory message) external pure returns (bytes32);

    function onMessage(SJMessage calldata message) external;

    function setOppositeSjRouter(address sourceSjRouter_) external;
}
