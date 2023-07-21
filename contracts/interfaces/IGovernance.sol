pragma solidity ^0.8.19;

interface IGovernance {
    function addSourceAdapter(address adapter) external;

    function addDestinationAdapter(address adapter) external;

    function getSourceAdapters() external returns (address[] memory);

    function getDestinationAdapters() external returns (address[] memory);
}
