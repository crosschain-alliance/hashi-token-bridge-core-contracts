pragma solidity ^0.8.19;

import {SJToken} from "./SJToken.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";

contract SJFactory is ISJFactory {
    /// @inheritdoc ISJFactory
    function deploy(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingSourceTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) public payable returns (address) {
        address sjToken = address(
            new SJToken{salt: hex"0000000000000000000000000000000000000000000000000000000000000000"}(
                underlyingTokenAddress,
                underlyingTokenName,
                underlyingSourceTokenSymbol,
                underlyingTokenDecimals,
                underlyingTokenChainId,
                sjRouter
            )
        );

        emit SJTokenDeployed(sjToken);
        return sjToken;
    }

    /// @inheritdoc ISJFactory
    function getBytecode(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingSourceTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(SJToken).creationCode;

        return
            abi.encodePacked(
                bytecode,
                abi.encode(
                    underlyingTokenAddress,
                    underlyingTokenName,
                    underlyingSourceTokenSymbol,
                    underlyingTokenDecimals,
                    underlyingTokenChainId,
                    sjRouter
                )
            );
    }

    /// @inheritdoc ISJFactory
    function getSJTokenAddress(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingSourceTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter
    ) public view returns (address) {
        bytes memory bytecode = getBytecode(
            underlyingTokenAddress,
            underlyingTokenName,
            underlyingSourceTokenSymbol,
            underlyingTokenDecimals,
            underlyingTokenChainId,
            sjRouter
        );

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                hex"0000000000000000000000000000000000000000000000000000000000000000",
                                keccak256(bytecode)
                            )
                        )
                    )
                )
            );
    }
}
