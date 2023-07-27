pragma solidity ^0.8.19;

interface IGovernance {
    function addSourceAdapter(address adapter) external;

    function addDestinationAdapter(address adapter) external;

    function getDestinationAdapters() external view returns (address[] memory);

    function getSJDispatcherByChainId(uint256 chainId) external view returns (address);

    function getSourceAdapters() external view returns (address[] memory);

    function setSJDispatcherByChainId(uint256 chainId, address sjDispatcher) external;

    function getSJReceiverByChainId(uint256 chainId) external view returns (address);

    function setSJReceiverByChainId(uint256 chainId, address jsReceiver) external;
}
