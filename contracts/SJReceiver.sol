pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {ISJReceiver} from "./interfaces/ISJReceiver.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";

error NotYaru();
error InvalidSJDispatcher();
error MessageAlreadyProcessed(SJMessage message);
error SJTokenNotCreated(address sjTokenAddress);
error MessageAlreadyAdvanced(SJMessage message);

contract SJReceiver is ISJReceiver, Context {
    using SafeERC20 for ISJToken;
    using SafeERC20 for IERC20;

    address public immutable yaru;
    address public immutable sjFactory;

    mapping(bytes32 => bool) private _processedMessages;
    mapping(bytes32 => address) private _advancedMessagesExecutors;

    modifier onlyYaru() {
        if (_msgSender() != yaru) {
            revert NotYaru();
        }

        _;
    }

    constructor(address yaru_, address sjFactory_) {
        yaru = yaru_;
        sjFactory = sjFactory_;
    }

    /// @inheritdoc ISJReceiver
    function advanceMessage(SJMessage calldata message) external {
        bytes32 messageId = getMessageId(message);

        if (_advancedMessagesExecutors[messageId] != address(0)) revert MessageAlreadyAdvanced(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);

        address executor = _msgSender();
        _advancedMessagesExecutors[messageId] = executor;

        if (block.chainid == message.underlyingTokenChainId) {
            IERC20(message.underlyingTokenAddress).safeTransferFrom(executor, address(this), message.amount);
            IERC20(message.underlyingTokenAddress).safeTransfer(message.receiver, message.amount);
        } else {
            address sjTokenAddress = ISJFactory(sjFactory).getSJTokenAddress(
                message.underlyingTokenAddress,
                message.underlyingTokenName,
                message.underlyingTokenSymbol,
                message.underlyingTokenDecimals,
                message.underlyingTokenChainId
            );
            if (sjTokenAddress.code.length == 0) revert SJTokenNotCreated(sjTokenAddress);

            ISJToken(sjTokenAddress).safeTransferFrom(executor, address(this), message.amount);
            ISJToken(sjTokenAddress).safeTransfer(message.receiver, message.amount);
        }

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
    function onMessage(SJMessage calldata message) external onlyYaru {
        // TODO: Yaru.executeMessages invokes this contract in this way:
        // (bool success, bytes memory returnData) = address(message.to).call(message.data);
        // How can we be sure that sjMessage.sender is actually SJDispatcher?
        // An attacker could generate fake sjMessage (within a fake SJDispatcher on the source chain) by using the address of
        // SJDispatcher (hardcodedSJDispatcherAddress):
        //
        //
        // SJMessage memory sjMessage = SJMessage(
        //     salt,
        //     block.chainid,
        //     underlyingTokenChainId,
        //     amount,
        //     - address(this),
        //     + hardcodedSJDispatcherAddress,
        //     receiver,
        //     underlyingTokenAddress,
        //     underlyingTokenDecimals,
        //     underlyingTokenName,
        //     underlyingTokenSymbol
        // );
        //
        // bytes memory sjData = abi.encodeWithSignature(
        //     "onMessage((bytes32,uint256,uint256,uint256,address,address,address,uint8,string,string))",
        //     sjMessage
        // );
        //
        // address sjReceiver = IGovernance(governance).getSJReceiverByChainId(destinationChainId);
        //
        // Message[] memory messages = new Message[](1);
        // messages[0] = Message(sjReceiver, destinationChainId, sjData);
        //
        // IYaho(yaho).dispatchMessagesToAdapters(
        //     messages,
        //     IGovernance(governance).getSourceAdapters(),
        //     IGovernance(governance).getDestinationAdapters()
        // );
        //
        //
        // In this way an attacker could mint an SJToken without depositing the collateral.
        // Hashi should pass the address of who dispatched the message here.

        bytes32 messageId = getMessageId(message);

        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        _processedMessages[messageId] = true;

        address sjTokenAddress = ISJFactory(sjFactory).getSJTokenAddress(
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
            ? ISJToken(sjTokenAddress).xReleaseCollateral(effectiveReceiver, message.amount)
            : ISJToken(sjTokenAddress).xMint(effectiveReceiver, message.amount);

        emit MessageProcessed(message);
    }
}
