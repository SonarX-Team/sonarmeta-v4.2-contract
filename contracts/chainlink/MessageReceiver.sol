// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import "../SonarMeta.sol";

/// @title SonarMeta Chainlink CCIP message receiver contract
contract MessageReceiver is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error SourceChainNotAllowlisted(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowlisted(address sender); // Used when the sender has not been allowlisted by the contract owner.

    // Event emitted when a message is received from the source chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    // Mapping to keep track of allowlisted source chains.
    mapping(uint64 => bool) public allowlistedSourceChains;

    // Mapping to keep track of allowlisted senders.
    mapping(address => bool) public allowlistedSenders;

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    SonarMeta private s_sonarMeta;

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowlisted(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowlisted(_sender);
        _;
    }

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _sonarMetaImpAddr The address of the SonarMeta main contract.
    constructor(
        address _router,
        address _sonarMetaImpAddr
    ) CCIPReceiver(_router) {
        s_sonarMeta = SonarMeta(_sonarMetaImpAddr);
    }

    /// @dev Updates the allowlist status of a source chain for transactions.
    function allowlistSourceChain(
        uint64 _sourceChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a sender for transactions.
    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    /// Handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory _any2EvmMessage
    )
        internal
        override
        onlyAllowlisted(
            _any2EvmMessage.sourceChainSelector,
            abi.decode(_any2EvmMessage.sender, (address))
        ) // Make sure source chain and sender are allowlisted
    {
        // Call function defined in SonarMeta contract
        (bool success, ) = address(s_sonarMeta).call(_any2EvmMessage.data);
        require(success, "CCIP failed");

        s_lastReceivedMessageId = _any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(_any2EvmMessage.data, (string)); // abi-decoding of the sent text

        emit MessageReceived(
            _any2EvmMessage.messageId,
            _any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(_any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(_any2EvmMessage.data, (string))
        );
    }

    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }
}
