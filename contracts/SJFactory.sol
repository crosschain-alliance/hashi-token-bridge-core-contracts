pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SJToken} from "./SJToken.sol";
import {ISJFactory} from "./interfaces/ISJFactory.sol";

contract SJFactory is ISJFactory, Ownable {
    address public immutable sjDispatcher;
    address public sjReceiver;

    constructor(address sjDispatcher_) {
        sjDispatcher = sjDispatcher_;
    }

    /// @inheritdoc ISJFactory
    function deploy(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingSourceTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId
    ) public payable returns (address) {
        address sjToken = address(
            new SJToken{salt: hex"0000000000000000000000000000000000000000000000000000000000000000"}(
                underlyingTokenAddress,
                underlyingTokenName,
                underlyingSourceTokenSymbol,
                underlyingTokenDecimals,
                underlyingTokenChainId,
                sjDispatcher,
                sjReceiver
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
        uint256 underlyingTokenChainId
    ) public view returns (bytes memory) {
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
                    sjDispatcher,
                    sjReceiver
                )
            );
    }

    /// @inheritdoc ISJFactory
    function getSJTokenAddress(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingSourceTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId
    ) public view returns (address) {
        bytes memory bytecode = getBytecode(
            underlyingTokenAddress,
            underlyingTokenName,
            underlyingSourceTokenSymbol,
            underlyingTokenDecimals,
            underlyingTokenChainId
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

    function setSJReceiver(address sjReceiver_) external onlyOwner {
        sjReceiver = sjReceiver_;
    }
}
