pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Utils} from "./libraries/Utils.sol";
import {ISJToken} from "./interfaces/ISJToken.sol";

error InvalidSJTransfer();
error InvalidSJReceiver();

contract SJToken is ISJToken, ERC20 {
    using SafeERC20 for IERC20;

    address public immutable UNDERLYING_TOKEN_ADDRESS;
    uint8 public immutable UNDERLYING_TOKEN_DECIMALS;
    uint256 public immutable UNDERLYING_TOKEN_CHAIN_ID;
    address public immutable SJ_ROUTER;
    // NOTE: Immutable variables cannot have a non-value type
    string public UNDERLYING_TOKEN_NAME;
    string public UNDERLYING_TOKEN_SYMBOL;

    modifier onlySJRouter() {
        if (_msgSender() != SJ_ROUTER) {
            revert InvalidSJReceiver();
        }

        _;
    }

    constructor(
        address underlyingTokenAddress,
        string memory underlyingTokenName,
        string memory underlyingTokenSymbol,
        uint8 underlyingTokenDecimals,
        uint256 underlyingTokenChainId,
        address sjRouter_
    ) ERC20(string.concat("SJ ", underlyingTokenName), string.concat("*", underlyingTokenSymbol)) {
        // TODO: check parameters validity
        SJ_ROUTER = sjRouter_;
        UNDERLYING_TOKEN_DECIMALS = underlyingTokenDecimals;
        UNDERLYING_TOKEN_ADDRESS = underlyingTokenAddress;
        UNDERLYING_TOKEN_CHAIN_ID = underlyingTokenChainId;
        underlyingTokenName = underlyingTokenName;
        underlyingTokenSymbol = underlyingTokenSymbol;
    }

    /// @inheritdoc ISJToken
    function burn(address account, uint256 amount) external onlySJRouter {
        _burn(account, amount);
    }

    /// @inheritdoc ISJToken
    function mint(address account, uint256 amount) external onlySJRouter {
        _mint(account, amount);
    }

    /// @inheritdoc ISJToken
    function releaseCollateral(address account, uint256 amount) external onlySJRouter {
        IERC20(UNDERLYING_TOKEN_ADDRESS).safeTransfer(
            account,
            Utils.normalizeAmountToRealDecimals(amount, UNDERLYING_TOKEN_DECIMALS)
        );
    }
}
