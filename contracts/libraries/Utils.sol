pragma solidity ^0.8.19;

library Utils {
    function normalizeAmountTo18Decimals(uint256 amount, uint256 decimals) internal pure returns (uint256) {
        return amount * (10 ** (18 - decimals));
    }

    function normalizeAmountToRealDecimals(uint256 amount, uint256 decimals) internal pure returns (uint256) {
        return amount / (10 ** (18 - decimals));
    }

    function isCurrentChainId(uint256 chainId) internal view returns (bool) {
        return block.chainid == chainId;
    }
}
