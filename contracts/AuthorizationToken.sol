// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LSP7Mintable} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/presets/LSP7Mintable.sol";
import {_LSP4_TOKEN_TYPE_DATA_KEY, TokenType} from "./utils/TokenTypes.sol";

/// @notice LSP7 contract to correspond a certain LSP8 authorization token.
/// You can view the former implementation with ERC-1155 in the former folder - ./former/Auhtorization.sol
contract AuthorizationToken is LSP7Mintable {
    constructor(address _initialOwner, address _to)
        LSP7Mintable(
            "SonarMeta Network Edge Token",
            "SMNET",
            _initialOwner,
            true
        )
    {
        // Set the type of the token
        _setData(_LSP4_TOKEN_TYPE_DATA_KEY, abi.encode(TokenType.NFT));

        uint256 claimAount = 1;

        // mint the total number of authorization tokens that the LSP8 Collection owns
        _mint({
            to: _to,
            amount: claimAount,
            force: true,
            data: abi.encodePacked(
                "Claiming",
                claimAount,
                "New network edge has been claimed!"
            )
        });
    }
}
