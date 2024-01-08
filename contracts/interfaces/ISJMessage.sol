pragma solidity ^0.8.19;

struct SJMessage {
    bytes32 salt;
    uint256 sourceChainId;
    uint256 destinationChainId;
    uint256 amount;
    uint256 fastLaneFeeAmount;
    address from;
    address to;
    address tokenCreator;
    string tokenName;
    string tokenSymbol;
}
