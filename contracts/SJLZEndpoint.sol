pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILayerZeroEndpoint} from "@lz/solidity-examples/contracts/lzApp/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@lz/solidity-examples/contracts/lzApp/interfaces/ILayerZeroReceiver.sol";
import {Message} from "./interfaces/hashi/IMessage.sol";
import {IYaho} from "./interfaces/hashi/IYaho.sol";
import {IYaru} from "./interfaces/hashi/IYaru.sol";

contract SJLZEndpoint is ILayerZeroEndpoint, Ownable {
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;

    address public immutable YAHO;
    address public immutable YARU;
    uint16 public immutable SOURCE_CHAIN_ID;

    address public oppositeLzEndpoint;
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    mapping(uint64 => mapping(bytes => uint64)) private _inboundNonces;
    mapping(uint64 => mapping(address => uint64)) private _outboundNonces;
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    error NotYaru(address caller, address expectedYaru);
    error NotOppositeLzEndpoint(address caller, address expectedLzEndpoint);
    error InvalidSourceChainId(uint16 sourceChainId, uint16 expectedSourceChainId);
    error InvalidNonce(uint64 nonce, uint64 expectedNonce);
    error NoStoredPayload();
    error InvalidPayload();
    error Reentrancy();

    event PayloadCleared(uint16 srcChainId, bytes srcAddress, uint64 nonce, address dstAddress);

    modifier sendNonReentrant() {
        if (_send_entered_state != _NOT_ENTERED) revert Reentrancy();
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }

    modifier receiveNonReentrant() {
        if (_receive_entered_state != _NOT_ENTERED) revert Reentrancy();
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    constructor(address yaho, address yaru, uint16 sourceChainId) {
        YAHO = yaho;
        YARU = yaru;
        SOURCE_CHAIN_ID = sourceChainId;
    }

    function send(
        uint16 dstChainId,
        bytes calldata destination,
        bytes calldata payload,
        address payable /*refundAddress,*/,
        address /*zroPaymentAddress,*/,
        bytes calldata /*adapterParams*/
    ) external payable sendNonReentrant {
        // TODO: get from governance or using another technique. At the moment we suppose that all routers have the same address
        address[] memory messageRelays = new address[](0);
        address[] memory adapters = new address[](0);

        address destinationAddress = address(uint160(bytes20(destination)));
        bytes memory data = abi.encodeWithSignature(
            "receivePayload(uint16,bytes,address,uint64,uint256,bytes)",
            uint16(block.chainid),
            abi.encodePacked(msg.sender, destinationAddress),
            destinationAddress,
            _outboundNonces[dstChainId][msg.sender],
            350000,
            payload
        );

        Message[] memory messages = new Message[](1);
        messages[0] = Message(oppositeLzEndpoint, dstChainId, data);
        IYaho(YAHO).dispatchMessagesToAdapters(messages, messageRelays, adapters);

        unchecked {
            ++_outboundNonces[dstChainId][msg.sender];
        }
    }

    function receivePayload(
        uint16 srcChainId,
        bytes calldata path,
        address dstAddress,
        uint64 nonce,
        uint256 gasLimit,
        bytes calldata payload
    ) external receiveNonReentrant {
        if (msg.sender != YARU) revert NotYaru(msg.sender, YARU);
        address lzEndpoint = IYaru(YARU).sender();

        if (lzEndpoint != oppositeLzEndpoint) revert NotOppositeLzEndpoint(lzEndpoint, oppositeLzEndpoint);
        if (srcChainId != SOURCE_CHAIN_ID) revert InvalidSourceChainId(srcChainId, SOURCE_CHAIN_ID);

        // TODO: check used adapters IYaru(YARU).adapters()

        uint64 expectedNonce = _inboundNonces[srcChainId][path];
        if (nonce != expectedNonce) revert InvalidNonce(nonce, expectedNonce);
        unchecked {
            ++_inboundNonces[srcChainId][path];
        }

        storedPayload[srcChainId][path] = StoredPayload(uint64(payload.length), dstAddress, keccak256(payload));

        ILayerZeroReceiver(dstAddress).lzReceive{gas: gasLimit}(srcChainId, path, nonce, payload);
    }

    function getInboundNonce(uint16 srcChainId, bytes calldata srcAddress) external view returns (uint64) {
        return _inboundNonces[srcChainId][srcAddress];
    }

    function getOutboundNonce(uint16 dstChainId, address srcAddress) external view returns (uint64) {
        return _outboundNonces[dstChainId][srcAddress];
    }

    function estimateFees(
        uint16 /*dstChainId,*/,
        address /*userApplication,*/,
        bytes calldata /*payload,*/,
        bool /*payInZRO,*/,
        bytes calldata /*adapterParam*/
    ) external view returns (uint nativeFee, uint zroFee) {
        // TODO
        return (0, 0);
    }

    function getChainId() external view returns (uint16) {
        // TODO
        return 0;
    }

    function retryPayload(uint16 srcChainId, bytes calldata path, bytes calldata payload) external {
        StoredPayload storage sp = storedPayload[srcChainId][path];
        if (sp.payloadHash == bytes32(0)) revert NoStoredPayload();
        if (payload.length != sp.payloadLength || keccak256(payload) != sp.payloadHash) revert InvalidPayload();

        address dstAddress = sp.dstAddress;
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = _inboundNonces[srcChainId][path];

        ILayerZeroReceiver(dstAddress).lzReceive(srcChainId, path, nonce, payload);
        emit PayloadCleared(srcChainId, path, nonce, dstAddress);
    }

    function hasStoredPayload(uint16 srcChainId, bytes calldata path) external view returns (bool) {
        StoredPayload storage sp = storedPayload[srcChainId][path];
        return sp.payloadHash != bytes32(0);
    }

    function getSendLibraryAddress(address userApplication) external view returns (address) {
        return address(this);
    }

    function getReceiveLibraryAddress(address userApplication) external view returns (address) {
        return address(this);
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getConfig(
        uint16 version,
        uint16 chainId,
        address userApplication,
        uint configType
    ) external view returns (bytes memory) {
        return "";
    }

    function getSendVersion(address userApplication) external view returns (uint16) {
        return 1;
    }

    function getReceiveVersion(address userApplication) external view returns (uint16) {
        return 1;
    }

    function setConfig(uint16 version, uint16 chainId, uint configType, bytes calldata config) external {}

    function setSendVersion(uint16 version) external {}

    function setReceiveVersion(uint16 version) external {}

    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external {}

    function setOppositeLzEndpoint(address oppositeLzEndpoint_) external onlyOwner {
        oppositeLzEndpoint = oppositeLzEndpoint_;
    }
}
