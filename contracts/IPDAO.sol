// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta IP DAO contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract IPDAO is Ownable, ReentrancyGuard {
    mapping(address => bool) private members;
    uint256 private memberCount;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a member has been added
    event MemberAdded(address indexed memberAddr);

    /// @notice Emitted when a member has been removed
    event MemberRemoved(address indexed memberAddr);

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor() Ownable(msg.sender) {}

    /// @notice Add a member to this IP DAO by its owner
    /// @param _memberAddr The member address to be added
    function addMember(address _memberAddr) external onlyOwner nonReentrant {
        require(
            members[_memberAddr],
            "Add error: This address has been already a member."
        );

        members[_memberAddr] = true;
        memberCount++;

        emit MemberAdded(_memberAddr);
    }

    /// @notice Remove a member from this IP DAO by its owner
    /// @param _memberAddr The member address to be removed
    function removeMember(address _memberAddr) external onlyOwner nonReentrant {
        require(
            members[_memberAddr],
            "Remove error: This address is not a member."
        );

        delete members[_memberAddr];
        memberCount--;

        emit MemberRemoved(_memberAddr);
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Check if the given address is a member of this IP DAO
    function isMember(address _memberAddr) external view returns (bool) {
        return members[_memberAddr];
    }

    /// @notice Get the total account of members of this IP DAO
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }
}
