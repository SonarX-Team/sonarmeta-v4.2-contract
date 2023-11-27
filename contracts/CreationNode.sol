// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC725Y} from "@erc725/smart-contracts/contracts/ERC725Y.sol";

/// @notice Currently, in order to use ERC-6551 token-bound account,
/// We cannot use type ADDRESS to represent a tokenID
/// Since ERC-6551 createAcount method needs type uint256 for tokenId to deploy
/// We wonder if there is any opportunity to make Universal Profile
/// a more straightforward, doable, and creative way to replace that ERC-6551 TBA

/// @notice So, in fact, this CreationNode is just an examply by now
contract CreationNode is ERC725Y {
    bytes32 constant _LSP8_REFERENCE_CONTRACT =
        0x708e7b881795f2e6b6c2752108c177ec89248458de3bf69d0d43480b3e5034e6;

    constructor(address nftOwner, address creationCollection)
        ERC725Y(nftOwner)
    {
        /**
         * @dev set the reference to the NFT collection that this metadata contract belongs to
         *
         * {
         *     "name": "LSP8ReferenceContract",
         *     "key": "0x708e7b881795f2e6b6c2752108c177ec89248458de3bf69d0d43480b3e5034e6",
         *     "keyType": "Singleton",
         *     "valueType": "(address, bytes32)",
         *     "valueContent": "(Address, bytes32)"
         * }
         */
        _setData(
            _LSP8_REFERENCE_CONTRACT,
            abi.encodePacked(
                creationCollection,
                bytes32(bytes20(address(this)))
            )
        );
    }
}
