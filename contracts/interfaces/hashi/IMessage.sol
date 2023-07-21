// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

struct Message {
    address to;
    uint256 toChainId;
    bytes data;
}
