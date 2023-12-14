// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./Creation.sol";

/// @title SonarMeta authorization contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
/// @notice ERC-1155: authorization tokenID => ( creation tbaAddr => contribution amount )
/// One authorization tokenID only represents for one Creation tokenID (tokenIDs are the same)
contract Authorization is ERC1155, Ownable, ERC1155Supply {
    string private _name;
    string private _symbol;

    Creation private s_creation;

    constructor(
        string memory name_,
        string memory symbol_,
        address _creationImpAddr,
        address _initialOwner
    )
        ERC1155("https://en.sonarmeta.com/api/metadata/authorization/{id}")
        Ownable(_initialOwner)
    {
        _name = name_;
        _symbol = symbol_;
        s_creation = Creation(_creationImpAddr);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }

    /// @notice Claim authorization token with the corresponding tokenID and mint it up to the maximum limit
    /// @param _issuer The issuer token-bound account address
    /// @param _tokenId The corresponding tokenID
    /// @param _maxSupply The maximum limit of this authorization token, e.g. 10,000,000
    function initialClaim(
        address _issuer,
        uint256 _tokenId,
        uint256 _maxSupply
    ) public onlyOwner {
        require(_issuer != address(0), "Destination address can't be zero.");
        require(
            !exists(_tokenId),
            "The given tokenID has been already claimed."
        );

        _mint(_issuer, _tokenId, (_maxSupply * 19) / 20, ""); // 95%(9,500,000) for node itself
        _mint(owner(), _tokenId, (_maxSupply * 1) / 20, ""); // 5%(50,000) for the SonarMeta protocol
    }

    /// @notice Get all token IDs held by a specific address
    /// @param _owner the address of the given owner
    /// @return All tokenIDs that this owner has
    function getTokenIds(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 count = 0;

        // Count the number of token IDs held by the address
        for (uint256 i = 1; i <= s_creation.totalSupply(); i++)
            if (balanceOf(_owner, i) > 0) count++;

        // Populate the array with token IDs
        uint256[] memory tokenIds = new uint256[](count);
        count = 0;

        for (uint256 i = 1; i <= s_creation.totalSupply(); i++)
            if (balanceOf(_owner, i) > 0) {
                tokenIds[count] = i;
                count++;
            }

        return tokenIds;
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
