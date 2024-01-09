pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OFTV2} from "@lz/solidity-examples/contracts/token/oft/v2/OFTV2.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";

contract SJToken is ISJToken, OFTV2 {
    using SafeERC20 for IERC20;

    bool public immutable IS_NATIVE;
    address public immutable UNDERLYING_TOKEN_ADDRESS;

    constructor(
        address underlyingTokenAddress,
        bool isNative,
        string memory name,
        string memory symbol,
        uint8 sharedDecimals,
        address lzEndpoint
    ) OFTV2(name, symbol, sharedDecimals, lzEndpoint) {
        IS_NATIVE = isNative;
        UNDERLYING_TOKEN_ADDRESS = underlyingTokenAddress;
    }

    function xTransfer(
        uint256 destinationChainId,
        address to,
        uint256 amount //uint256 fastLaneFeeAmount
    ) external payable {
        if (destinationChainId != block.chainid && IS_NATIVE) {
            IERC20(UNDERLYING_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), amount);
            _mint(msg.sender, amount);
        }

        _send(
            msg.sender,
            uint16(destinationChainId),
            _addressToBytes32(to),
            amount,
            payable(address(0)),
            address(0),
            abi.encodePacked(uint16(PT_SEND), uint256(500000))
        );
    }

    function unwrap(address to, uint256 amount) external {
        if (!IS_NATIVE) revert NotNative();
        _burn(msg.sender, amount);
        IERC20(UNDERLYING_TOKEN_ADDRESS).safeTransfer(to, amount);
    }
}
