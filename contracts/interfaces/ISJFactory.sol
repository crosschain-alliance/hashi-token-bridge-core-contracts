pragma solidity ^0.8.19;

/**
 * @title ISJFactory
 * @author Saje Function
 *
 * @notice
 */
interface ISJFactory {
    event SJTokenDeployed(address sjTokenAddress);

    function deploy(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) external payable returns (address);

    function getBytecode(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) external view returns (bytes memory);

    function getSJTokenAddress(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) external view returns (address);
}
