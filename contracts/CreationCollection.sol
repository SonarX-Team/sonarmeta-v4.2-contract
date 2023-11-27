// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LSP8Mintable} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/presets/LSP8Mintable.sol";
import {_LSP8_TOKENID_TYPE_ADDRESS, _LSP8_TOKENID_TYPE_NUMBER} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_TOKEN_TYPE_DATA_KEY, TokenType} from "./utils/TokenTypes.sol";

/// @title SonarMeta creation node collection implemented by LSP-8
/// You can view the former implementation with ERC-721 in the former folder - ./former/Creation.sol
contract CreationCollection is LSP8Mintable {
    /// @notice Currently, in order to use ERC-6551 token-bound account,
    /// We cannot use type ADDRESS to represent a tokenID
    /// Since ERC-6551 createAcount method needs type uint256 for tokenId to deploy
    /// We wonder if there is any opportunity to make Universal Profile
    /// a more straightforward, doable, and creative way to replace that ERC-6551 TBA
    constructor(address _initialOwner)
        LSP8Mintable(
            "SonarMeta Network Node Collection",
            "SMNNC",
            _initialOwner,
            _LSP8_TOKENID_TYPE_NUMBER
            // We really want to use _LSP8_TOKENID_TYPE_ADDRESS but not now
        )
    {
        // Set the type of the token
        _setData(_LSP4_TOKEN_TYPE_DATA_KEY, abi.encode(TokenType.COLLECTION));
    }
}
