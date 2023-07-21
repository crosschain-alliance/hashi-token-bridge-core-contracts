pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {ISJReceiver} from "./interfaces/ISJReceiver.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";

error NotYaru();
error InvalidSJDispatcher();
error MessageAlreadyProcessed(SJMessage message);
error SJTokenNotCreated(address sjTokenAddress);

contract SJReceiver is ISJReceiver, Context {
    using SafeERC20 for ISJToken;

    address public immutable yaru;
    address public immutable sjFactory;

    mapping(bytes32 => bool) private _executedMessages;
    mapping(bytes32 => bool) private _advancedMessages;
    mapping(bytes32 => address) private _advancedMessagesExecutors;

    modifier onlyYaru() {
        if (_msgSender() != yaru) {
            revert NotYaru();
        }

        _;
    }

    modifier messageSenderMustBeDispatcher(SJMessage calldata message) {
        // address dispatcher = IGovernance(sender).getDispatcherByChainId(message.sourceChainId)
        // if (dispatcher != _msgSender()) {
        //     revert InvalidSJDispatcher()
        // }
        _;
    }

    constructor(address yaru_, address sjFactory_) {
        yaru = yaru_;
        sjFactory = sjFactory_;
    }

    /// @inheritdoc ISJReceiver
    function advanceMessage(SJMessage calldata message) external {
        bytes32 messageId = getMessageId(message);
        if (_executedMessages[messageId] || _advancedMessages[messageId]) {
            revert MessageAlreadyProcessed(message);
        }

        address executor = _msgSender();
        address sjTokenAddress = ISJFactory(sjFactory).getSJTokenAddress(
            message.underlyingTokenAddress,
            message.underlyingTokenName,
            message.underlyingTokenSymbol,
            message.underlyingTokenDecimals,
            message.underlyingTokenChainId
        );
        if (sjTokenAddress.code.length == 0) {
            revert SJTokenNotCreated(sjTokenAddress);
        }

        // TODO: remove fee
        // uint256 fee = 0;
        ISJToken(sjTokenAddress).transferFrom(executor, message.receiver, message.amount);
        // ISJToken(sjTokenAddress).transfer(executor, fee);

        _advancedMessages[messageId];
        _advancedMessagesExecutors[messageId] = executor;
        emit MessageAdvanced(message);
    }

    /// @inheritdoc ISJReceiver
    function getMessageId(SJMessage memory message) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    message.salt,
                    message.sourceChainId,
                    message.underlyingTokenChainId,
                    message.amount,
                    message.sender,
                    message.receiver,
                    message.underlyingTokenAddress,
                    message.underlyingTokenDecimals,
                    message.underlyingTokenName,
                    message.underlyingTokenSymbol
                )
            );
    }

    /// @inheritdoc ISJReceiver
    function onMessage(SJMessage calldata message) external onlyYaru messageSenderMustBeDispatcher(message) {
        bytes32 messageId = getMessageId(message);
        if (_executedMessages[messageId]) {
            revert MessageAlreadyProcessed(message);
        }
        _executedMessages[messageId] = true;

        address sjTokenAddress = ISJFactory(sjFactory).getSJTokenAddress(
            message.underlyingTokenAddress,
            message.underlyingTokenName,
            message.underlyingTokenSymbol,
            message.underlyingTokenDecimals,
            message.underlyingTokenChainId
        );
        if (sjTokenAddress.code.length == 0) {
            revert SJTokenNotCreated(sjTokenAddress);
        }

        address effectiveReceiver = message.receiver;
        if (_advancedMessages[messageId]) {
            effectiveReceiver = _advancedMessagesExecutors[messageId];
        }

        if (block.chainid == message.underlyingTokenChainId) {
            ISJToken(sjTokenAddress).xReleaseCollateral(effectiveReceiver, message.amount);
        } else {
            ISJToken(sjTokenAddress).xMint(effectiveReceiver, message.amount);
        }

        emit MessageProcessed(message);
    }
}
