pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error NotGovernance();

contract Governance is Ownable {
    address[] private _sourceAdapters;
    address[] private _destinationAdapters;
    mapping(uint256 => address) private _chainIdSJReceivers;
    mapping(uint256 => address) private _chainIdSJDispatcher;

    function addSourceAdapter(address adapter) external onlyOwner {
        _sourceAdapters.push(adapter);
    }

    function addDestinationAdapter(address adapter) external onlyOwner {
        _destinationAdapters.push(adapter);
    }

    function getDestinationAdapters() external view returns (address[] memory) {
        return _destinationAdapters;
    }

    function getSJDispatcherByChainId(uint256 chainId) external view returns (address) {
        return _chainIdSJDispatcher[chainId];
    }

    function getSourceAdapters() external view returns (address[] memory) {
        return _sourceAdapters;
    }

    function setSJDispatcherByChainId(uint256 chainId, address sjDispatcher) external onlyOwner {
        _chainIdSJDispatcher[chainId] = sjDispatcher;
    }

    function getSJReceiverByChainId(uint256 chainId) external view returns (address) {
        return _chainIdSJReceivers[chainId];
    }

    function setSJReceiverByChainId(uint256 chainId, address sjReceiver) external onlyOwner {
        _chainIdSJReceivers[chainId] = sjReceiver;
    }
}
