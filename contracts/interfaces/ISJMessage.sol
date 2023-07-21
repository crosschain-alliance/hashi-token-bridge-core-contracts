pragma solidity ^0.8.19;

struct SJMessage {
    bytes32 messageId;
    uint256 sourceChainId;
    uint256 underlyingTokenChainId;
    uint256 amount;
    address sender;
    address receiver;
    address underlyingTokenAddress;
    uint8 underlyingTokenDecimals;
    string underlyingTokenName;
    string underlyingTokenSymbol;
}
