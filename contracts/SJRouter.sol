pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Utils} from "./libraries/Utils.sol";
import {IYaho} from "./interfaces/hashi/IYaho.sol";
import {Message} from "./interfaces/hashi/IMessage.sol";
import {IYaru} from "./interfaces/hashi/IYaru.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {ISJRouter} from "./interfaces/ISJRouter.sol";

contract SJRouter is ISJRouter, Ownable {
    using SafeERC20 for IERC20;

    address public immutable YAHO;
    address public immutable YARU;
    address public immutable SJ_FACTORY;
    address public OPPOSITE_SJ_ROUTER;

    mapping(bytes32 => bool) private _processedMessages;
    mapping(bytes32 => address) private _advancedMessagesExecutors;

    constructor(address yaho, address yaru, address sjFactory) {
        YAHO = yaho;
        YARU = yaru;
        SJ_FACTORY = sjFactory;
    }

    /// @inheritdoc ISJRouter
    function advanceMessage(SJMessage calldata message) external {
        bytes32 messageId = getMessageId(message);

        if (_advancedMessagesExecutors[messageId] != address(0)) revert MessageAlreadyAdvanced(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        if (message.fastLaneFeeAmount == 0) revert InvalidFastLaneFeeAmount(message.fastLaneFeeAmount);

        address executor = msg.sender;
        _advancedMessagesExecutors[messageId] = executor;

        uint256 effectiveAmount = message.amount - message.fastLaneFeeAmount;
        address sjToken = _maybeGetSjTokenAddress(
            message.underlyingTokenAddress,
            message.underlyingTokenName,
            message.underlyingTokenSymbol,
            message.underlyingTokenDecimals,
            message.underlyingTokenChainId
        );
        IERC20(sjToken).safeTransferFrom(executor, address(this), effectiveAmount);
        IERC20(sjToken).safeTransfer(message.receiver, effectiveAmount);

        emit MessageAdvanced(message);
    }

    /// @inheritdoc ISJRouter
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
    ) external {
        if (fastLaneFeeAmount > amount) revert InvalidFastLaneFeeAmount(fastLaneFeeAmount);

        address sjToken = _maybeGetSjTokenAddress(
            underlyingTokenAddress,
            underlyingTokenName,
            underlyingTokenSymbol,
            underlyingTokenDecimals,
            underlyingTokenChainId
        );

        bool isTokenUnderlyingChainId = block.chainid == underlyingTokenChainId;
        if (destinationChainId != block.chainid && isTokenUnderlyingChainId) {
            IERC20(underlyingTokenAddress).safeTransferFrom(msg.sender, sjToken, amount);
        } else if (destinationChainId != block.chainid && !isTokenUnderlyingChainId) {
            ISJToken(sjToken).burn(msg.sender, amount);
        } else {
            revert InvalidXtransfer();
        }

        bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()));
        SJMessage memory sjMessage = SJMessage(
            salt,
            block.chainid,
            underlyingTokenChainId,
            Utils.normalizeAmountTo18Decimals(amount, underlyingTokenDecimals),
            Utils.normalizeAmountTo18Decimals(fastLaneFeeAmount, underlyingTokenDecimals),
            address(this),
            receiver,
            underlyingTokenAddress,
            underlyingTokenDecimals,
            underlyingTokenName,
            underlyingTokenSymbol
        );

        bytes memory sjData = abi.encodeWithSignature(
            "onMessage((bytes32,uint256,uint256,uint256,uint256,address,address,address,uint8,string,string))",
            sjMessage
        );

        // TODO: get from governance or using another technique. At the moment we suppose that all routers have the same address
        address[] memory messageRelays = new address[](0);
        address[] memory adapters = new address[](0);

        Message[] memory messages = new Message[](1);
        messages[0] = Message(OPPOSITE_SJ_ROUTER, destinationChainId, sjData);

        IYaho(YAHO).dispatchMessagesToAdapters(messages, messageRelays, adapters);
        emit MessageDispatched(sjMessage);
    }

    /// @inheritdoc ISJRouter
    function getMessageId(SJMessage memory message) public pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }

    /// @inheritdoc ISJRouter
    function onMessage(SJMessage calldata message) external {
        if (msg.sender != YARU) revert NotYaru(msg.sender, YARU);
        address router = IYaru(YARU).sender();
        if (router != OPPOSITE_SJ_ROUTER) revert NotOppositeSJRouter(router, OPPOSITE_SJ_ROUTER);

        // TODO: check used adapters IYaru(YARU).adapters()

        bytes32 messageId = getMessageId(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        _processedMessages[messageId] = true;

        address sjToken = _maybeGetSjTokenAddress(
            message.underlyingTokenAddress,
            message.underlyingTokenName,
            message.underlyingTokenSymbol,
            message.underlyingTokenDecimals,
            message.underlyingTokenChainId
        );
        address advancedMessageExecutor = _advancedMessagesExecutors[messageId];
        address effectiveReceiver = advancedMessageExecutor != address(0) ? advancedMessageExecutor : message.receiver;
        block.chainid == message.underlyingTokenChainId
            ? ISJToken(sjToken).releaseCollateral(effectiveReceiver, message.amount)
            : ISJToken(sjToken).mint(effectiveReceiver, message.amount);
        emit MessageProcessed(message);
    }

    /// @inheritdoc ISJRouter
    function setOppositeSjRouter(address sourceSjRouter_) external onlyOwner {
        OPPOSITE_SJ_ROUTER = sourceSjRouter_;
    }

    function _maybeGetSjTokenAddress(
        address underlyingTokenAddress,
        string calldata underlyingTokenName,
        string calldata underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId
    ) internal view returns (address) {
        address sjToken = ISJFactory(SJ_FACTORY).getSJTokenAddress(
            underlyingTokenAddress,
            underlyingTokenName,
            underlyingTokenSymbol,
            underlyingTokenDecimals,
            underlyingTokenChainId,
            address(this)
        );
        if (sjToken.code.length == 0) revert TokenNotCreated(sjToken);
        return sjToken;
    }
}
