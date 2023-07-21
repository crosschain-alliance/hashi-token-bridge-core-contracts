pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {ISJReceiver} from "./interfaces/ISJReceiver.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";

error NotYaru();
error InvalidSJDispatcher();
error MessageAlreadyProcessed(SJMessage message);
error SJTokenNotCreated(address sjTokenAddress);

contract SJReceiver is ISJReceiver, Context {
    address public immutable yaru;
    address public immutable sjFactory;

    mapping(bytes32 => bool) private _msgExecuted;

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
    function getMessageHash(SJMessage memory message) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    message.messageId,
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
        bytes32 msgHash = getMessageHash(message);
        if (_msgExecuted[msgHash]) {
            revert MessageAlreadyProcessed(message);
        }
        _msgExecuted[msgHash] = true;

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

        if (block.chainid == message.underlyingTokenChainId) {
            ISJToken(sjTokenAddress).xReleaseCollateral(message.receiver, message.amount);
        } else {
            ISJToken(sjTokenAddress).xMint(message.receiver, message.amount);
        }

        emit MessageProcessed(message);
    }
}
