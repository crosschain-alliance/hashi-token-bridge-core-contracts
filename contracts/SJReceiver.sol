pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {ISJReceiver} from "./interfaces/ISJReceiver.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";
import {IYaru} from "./interfaces/hashi/IYaru.sol";

error NotYaru(address caller, address expectedYaru);
error NotSjDispatcher(address sjDispatcher, address expectedSjDispatcher);
error InvalidSJDispatcher();
error MessageAlreadyProcessed(SJMessage message);
error SJTokenNotCreated(address sjTokenAddress);
error MessageAlreadyAdvanced(SJMessage message);
error InvalidFastLaneFeeAmount(uint256 fastLaneFeeAmount);

contract SJReceiver is ISJReceiver, Context {
    using SafeERC20 for ISJToken;
    using SafeERC20 for IERC20;

    address public immutable YARU;
    address public immutable SJ_FACTORY;
    address public immutable SJ_DISPATCHER;

    mapping(bytes32 => bool) private _processedMessages;
    mapping(bytes32 => address) private _advancedMessagesExecutors;

    constructor(address yaru, address sjDispatcher, address sjFactory) {
        YARU = yaru;
        SJ_DISPATCHER = sjDispatcher;
        SJ_FACTORY = sjFactory;
    }

    /// @inheritdoc ISJReceiver
    function advanceMessage(SJMessage calldata message) external {
        bytes32 messageId = getMessageId(message);

        if (_advancedMessagesExecutors[messageId] != address(0)) revert MessageAlreadyAdvanced(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        if (message.fastLaneFeeAmount == 0) revert InvalidFastLaneFeeAmount(message.fastLaneFeeAmount);

        address executor = msg.sender;
        _advancedMessagesExecutors[messageId] = executor;

        uint256 effectiveAmount = message.amount - message.fastLaneFeeAmount;

        if (block.chainid == message.underlyingTokenChainId) {
            IERC20(message.underlyingTokenAddress).safeTransferFrom(executor, address(this), effectiveAmount);
            IERC20(message.underlyingTokenAddress).safeTransfer(message.receiver, effectiveAmount);
        } else {
            address sjTokenAddress = ISJFactory(SJ_FACTORY).getSJTokenAddress(
                message.underlyingTokenAddress,
                message.underlyingTokenName,
                message.underlyingTokenSymbol,
                message.underlyingTokenDecimals,
                message.underlyingTokenChainId
            );
            if (sjTokenAddress.code.length == 0) revert SJTokenNotCreated(sjTokenAddress);

            ISJToken(sjTokenAddress).safeTransferFrom(executor, address(this), effectiveAmount);
            ISJToken(sjTokenAddress).safeTransfer(message.receiver, effectiveAmount);
        }

        emit MessageAdvanced(message);
    }

    /// @inheritdoc ISJReceiver
    function getMessageId(SJMessage memory message) public pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }

    /// @inheritdoc ISJReceiver
    function onMessage(SJMessage calldata message) external {
        if (msg.sender != YARU) revert NotYaru(msg.sender, YARU);
        address sender = IYaru(YARU).sender();
        if (sender != SJ_DISPATCHER) revert NotSjDispatcher(sender, SJ_DISPATCHER);

        // TODO: check used adapters

        bytes32 messageId = getMessageId(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        _processedMessages[messageId] = true;

        address sjTokenAddress = ISJFactory(SJ_FACTORY).getSJTokenAddress(
            message.underlyingTokenAddress,
            message.underlyingTokenName,
            message.underlyingTokenSymbol,
            message.underlyingTokenDecimals,
            message.underlyingTokenChainId
        );
        if (sjTokenAddress.code.length == 0) revert SJTokenNotCreated(sjTokenAddress);

        address advancedMessageExecutor = _advancedMessagesExecutors[messageId];
        address effectiveReceiver = advancedMessageExecutor != address(0) ? advancedMessageExecutor : message.receiver;

        block.chainid == message.underlyingTokenChainId
            ? ISJToken(sjTokenAddress).releaseCollateral(effectiveReceiver, message.amount)
            : ISJToken(sjTokenAddress).mint(effectiveReceiver, message.amount);

        emit MessageProcessed(message);
    }
}
