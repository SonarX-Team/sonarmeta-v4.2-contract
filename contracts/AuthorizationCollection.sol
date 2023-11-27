// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import {AuthorizationToken} from "./AuthorizationToken.sol";
import {_LSP8_TOKENID_TYPE_ADDRESS} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_TOKEN_TYPE_DATA_KEY, TokenType} from "./utils/TokenTypes.sol";

/// @title SonarMeta authorization edge collection implemented by LSP-8
/// where each token is a LSP7 contract with a limited supply available.
/// You can view the former implementation with ERC-1155 in the former folder - ./former/Auhtorization.sol
contract AuthorizationCollection is
    LSP8IdentifiableDigitalAsset(
        "SonarMeta Network Edge Collection",
        "SMNEC",
        msg.sender,
        _LSP8_TOKENID_TYPE_ADDRESS
    )
{
    constructor() {
        // Set the type of the token
        _setData(_LSP4_TOKEN_TYPE_DATA_KEY, abi.encode(TokenType.COLLECTION));
    }

    bytes32 internal constant _LSP8_REFERENCE_CONTRACT_DATA_KEY =
        0x708e7b881795f2e6b6c2752108c177ec89248458de3bf69d0d43480b3e5034e6;

    // Track corresponding node => edge with their tokenIds, e.g. creation #1 => authorization #0xabcdabcd...
    mapping(bytes32 => bytes32) nodeToEdge;

    error FailedDeployingAuthorizationTokenContract();

    /// @notice claim a new corresponding authorization tokenId to the given creation
    /// @param _to The creationToken-bound account of the issuer creation token
    /// @param _creationTokenId The tokenId of the issuer creation token
    function claimNew(address _to, bytes32 _creationTokenId)
        external
        onlyOwner
    {
        try new AuthorizationToken(address(this), _to) returns (
            AuthorizationToken newAuthorizationToken
        ) {
            bytes32 authorizationTokenId = bytes32(
                abi.encode(address(newAuthorizationToken))
            );

            newAuthorizationToken.setData(
                _LSP8_REFERENCE_CONTRACT_DATA_KEY,
                abi.encodePacked(address(this), authorizationTokenId)
            );

            _mint({
                to: _to,
                tokenId: authorizationTokenId,
                force: false,
                data: ""
            });

            nodeToEdge[_creationTokenId] = authorizationTokenId;
        } catch (bytes memory) {
            revert FailedDeployingAuthorizationTokenContract();
        }
    }

    /// @notice increase _amount to a holder's creationToken-bound account as contribution bonus
    /// @param _to The creationToken-bound account of the holder creation token
    /// @param _amount The amount that the issuer wants to give
    /// @param _creationTokenId The tokenId of the holder creation token
    function increase(
        address _to,
        bytes32 _creationTokenId,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "Destination address can't be zero.");

        // Get the corresponding authorizationTokenId
        bytes32 authorizationTokenId = nodeToEdge[_creationTokenId];

        // Revert if authorizationTokenId does not exist
        _existsOrError(authorizationTokenId);

        // Decode authorizationTokenId to get the tokenId, which is an address
        // And get the implementation of the authorization token
        AuthorizationToken tokenImp = AuthorizationToken(
            abi.decode(abi.encodePacked(authorizationTokenId), (address))
        );

        // Call the public mint method
        tokenImp.mint({
            to: _to,
            amount: _amount,
            force: false,
            data: abi.encodePacked(
                "Increasing",
                _amount,
                "Edge has been increased!"
            )
        });
    }

    /// @notice Get authorization tokenId by its corresponding creation tokenId
    /// @param _creationTokenId The tokenId of a creation token
    function getEdgeByNode(bytes32 _creationTokenId)
        external
        view
        returns (bytes32)
    {
        return nodeToEdge[_creationTokenId];
    }
}
