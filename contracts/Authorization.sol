// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./utils/Counters.sol";

contract Authorization is ERC1155, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(address initialOwner)
        ERC1155("https://en.sonarmeta.com/api/metadata/authorization/{id}")
        Ownable(initialOwner)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintNew(address to, bytes memory data)
        public
        onlyOwner
        returns (uint256)
    {
        require(to != address(0), "Destination address can't be zero.");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId, 1, data);

        return tokenId;
    }

    function mintBatchNew(
        address to,
        uint256 amount,
        bytes memory data
    ) public onlyOwner returns (uint256[] memory) {
        require(to != address(0), "Destination address can't be zero.");

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();

            ids[i] = tokenId;
            amounts[i] = 1;
        }

        _mintBatch(to, ids, amounts, data);

        return ids;
    }

    function increaseContribution(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(to != address(0), "Destination address can't be zero.");

        _mint(to, tokenId, amount, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
