pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error NotGovernance();

contract Governance is Ownable {
    mapping(uint256 => address[]) private _chainIdSourceAdapters;
    mapping(uint256 => address[]) private _chainIdDestinationAdapters;
    mapping(uint256 => address) private _chainIdSJReceivers;
    mapping(uint256 => address) private _chainIdSJDispatcher;

    function addSourceAdapterByChainid(uint256 chainId, address adapter) external onlyOwner {
        _chainIdSourceAdapters[chainId].push(adapter);
    }

    function addDestinationAdapterByChainid(uint256 chainId, address adapter) external onlyOwner {
        _chainIdDestinationAdapters[chainId].push(adapter);
    }

    function getDestinationAdaptersByChainId(uint256 chainId) external view returns (address[] memory) {
        return _chainIdDestinationAdapters[chainId];
    }

    function getSJDispatcherByChainId(uint256 chainId) external view returns (address) {
        return _chainIdSJDispatcher[chainId];
    }

    function getSourceAdaptersByChainId(uint256 chainId) external view returns (address[] memory) {
        return _chainIdSourceAdapters[chainId];
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
