// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @title SonarMeta authorization contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
/// @notice ERC-1155: authorization tokenID => ( creation tbaAddr => contribution amount )
/// One authorization tokenID only represents for one Creation tokenID (tokenIDs are the same)
contract Authorization is ERC1155, Ownable, ERC1155Supply {
    constructor(address _initialOwner)
        ERC1155("https://en.sonarmeta.com/api/metadata/authorization/{id}")
        Ownable(_initialOwner)
    {}

    function setURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }

    function claimNew(address _to, uint256 _tokenId) public onlyOwner {
        require(_to != address(0), "Destination address can't be zero.");
        require(
            !exists(_tokenId),
            "The given tokenID has been already claimed."
        );

        _mint(_to, _tokenId, 1, "");
    }

    function increase(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public onlyOwner {
        require(_to != address(0), "Destination address can't be zero.");
        require(exists(_tokenId), "The given tokenID doesn't exist.");

        _mint(_to, _tokenId, _amount, "");
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
