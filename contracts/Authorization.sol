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
    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        address _initialOwner
    )
        ERC1155("https://en.sonarmeta.com/api/metadata/authorization/{id}")
        Ownable(_initialOwner)
    {
        _name = name_;
        _symbol = symbol_;
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

    /// @notice Claim authorization token with the corresponding tokenID and mint it up to the maximum limit.
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

        _mint(_issuer, _tokenId, (_maxSupply * 19) / 20, ""); // 95%(9,500,000) for node itself.
        _mint(owner(), _tokenId, (_maxSupply * 1) / 20, ""); // 5%(50,000) for SonarMeta protocol.
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

    /// @notice Get all token IDs held by a specific address
    /// @param _account the address of the account
    /// @return All tokenIDs that this account have
    function getTokenIds(
        address _account
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenIds;
        uint256 count;

        // Count the number of token IDs held by the address
        for (uint256 i = 1; i <= totalSupply(); i++)
            if (balanceOf(_account, i) > 0) count++;

        // Populate the array with token IDs
        tokenIds = new uint256[](count);
        count = 0;

        for (uint256 i = 1; i < totalSupply(); i++)
            if (balanceOf(_account, i) > 0) {
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
