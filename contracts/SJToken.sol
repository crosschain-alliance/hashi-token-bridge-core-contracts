pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Utils} from "./libraries/Utils.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";
import {ISJDispatcher} from "./interfaces/ISJDispatcher.sol";

error InvalidSJTransfer();
error InvalidSJReceiver();

contract SJToken is ISJToken, ERC20 {
    using SafeERC20 for IERC20;

    address public immutable underlyingTokenAddress;
    uint8 public immutable underlyingTokenDecimals;
    uint256 public immutable underlyingTokenChainId;
    address public immutable sjDispatcher;
    address public immutable sjReceiver;

    // NOTE: Immutable variables cannot have a non-value type
    string public underlyingTokenName;
    string public underlyingTokenSymbol;

    modifier onlySJReceiver() {
        if (_msgSender() != sjReceiver) {
            revert InvalidSJReceiver();
        }

        _;
    }

    constructor(
        address underlyingTokenAddress_,
        string memory underlyingTokenName_,
        string memory underlyingTokenSymbol_,
        uint8 underlyingTokenDecimals_,
        uint256 underlyingTokenChainId_,
        address sjDispatcher_,
        address sjReceiver_
    ) ERC20(string.concat("SJ ", underlyingTokenName_), string.concat("*", underlyingTokenSymbol_)) {
        // TODO: check parameters validity
        sjDispatcher = sjDispatcher_;
        sjReceiver = sjReceiver_;
        underlyingTokenDecimals = underlyingTokenDecimals_;
        underlyingTokenAddress = underlyingTokenAddress_;
        underlyingTokenChainId = underlyingTokenChainId_;
        underlyingTokenName = underlyingTokenName_;
        underlyingTokenSymbol = underlyingTokenSymbol_;
    }

    /// @inheritdoc ISJToken
    function xTransfer(uint256 destinationChainId, address account, uint256 amount) external {
        bool isTokenUnderlyingChainId = block.chainid == underlyingTokenChainId;

        if (destinationChainId != block.chainid && isTokenUnderlyingChainId) {
            IERC20(underlyingTokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
        } else if (destinationChainId != block.chainid && !isTokenUnderlyingChainId) {
            _burn(_msgSender(), amount);
        } else {
            revert InvalidSJTransfer();
        }

        ISJDispatcher(sjDispatcher).dispatch(
            destinationChainId,
            underlyingTokenAddress,
            underlyingTokenName,
            underlyingTokenSymbol,
            underlyingTokenDecimals,
            underlyingTokenChainId,
            Utils.normalizeAmountTo18Decimals(amount, underlyingTokenDecimals),
            account
        );
    }

    /// @inheritdoc ISJToken
    function xMint(address account, uint256 amount) external onlySJReceiver {
        _mint(account, amount);
    }

    /// @inheritdoc ISJToken
    function xReleaseCollateral(address account, uint256 amount) external onlySJReceiver {
        IERC20(underlyingTokenAddress).safeTransfer(
            account,
            Utils.normalizeAmountToRealDecimals(amount, underlyingTokenDecimals)
        );
    }
}
