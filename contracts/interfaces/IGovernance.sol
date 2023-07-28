pragma solidity ^0.8.19;

interface IGovernance {
    function addMessageRelayByChainid(uint256 chainId, address adapter) external;

    function addDestinationAdapterByChainid(uint256 chainId, address adapter) external;

    function getDestinationAdaptersByChainId(uint256 chainId) external view returns (address[] memory);

    function getSJDispatcherByChainId(uint256 chainId) external view returns (address);

    function getMessageRelayByChainId(uint256 chainId) external view returns (address[] memory);

    function setSJDispatcherByChainId(uint256 chainId, address sjDispatcher) external;

    function getSJReceiverByChainId(uint256 chainId) external view returns (address);

    function setSJReceiverByChainId(uint256 chainId, address sjReceiver) external;
}
