pragma solidity ^0.8.19;

import {ISJDispatcher} from "./interfaces/ISJDispatcher.sol";
import {SJMessage} from "./interfaces/ISJMessage.sol";
import {IYaho} from "./interfaces/hashi/IYaho.sol";
import {Message} from "./interfaces/hashi/IMessage.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";

contract SJDispatcher is ISJDispatcher {
    address public immutable yaho;
    address public immutable governance;

    constructor(address yaho_, address governance_) {
        yaho = yaho_;
        governance = governance_;
    }

    /// @inheritdoc ISJDispatcher
    function dispatch(
        uint256 destinationChainId,
        address underlyingTokenAddress,
        string calldata underlyingTokenName,
        string calldata underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        uint256 amount,
        address receiver
    ) external {
        bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()));

        SJMessage memory sjMessage = SJMessage(
            salt,
            block.chainid,
            underlyingTokenChainId,
            amount,
            address(this),
            receiver,
            underlyingTokenAddress,
            underlyingTokenDecimals,
            underlyingTokenName,
            underlyingTokenSymbol
        );

        bytes memory sjData = abi.encodeWithSignature(
            "onMessage((bytes32,uint256,uint256,uint256,address,address,address,uint8,string,string))",
            sjMessage
        );

        address sjReceiver = IGovernance(governance).getSJReceiverByChainId(destinationChainId);

        Message[] memory messages = new Message[](1);
        messages[0] = Message(sjReceiver, destinationChainId, sjData);

        IYaho(yaho).dispatchMessagesToAdapters(
            messages,
            IGovernance(governance).getMessageRelayByChainId(destinationChainId),
            IGovernance(governance).getDestinationAdaptersByChainId(destinationChainId)
        );

        emit MessageDispatched(sjMessage);
    }
}
