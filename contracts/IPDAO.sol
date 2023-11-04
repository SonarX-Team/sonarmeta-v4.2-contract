// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SonarMeta IPDAO contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract IPDAO is Ownable {
    uint256 public memberCount;
    mapping(address => bool) public members;

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

    /// @notice Add a member to this IPDAO
    /// @param _memberAddr The member address to be added
    function addMember(address _memberAddr) external {
        require(
            members[_memberAddr],
            "Add error: This address has been already a member."
        );

        members[_memberAddr] = true;
        memberCount++;

        emit MemberAdded(_memberAddr);
    }

    /// @notice Remove a member from this IPDAO
    /// @param _memberAddr The member address to be removed
    function removeMember(address _memberAddr) external {
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

    /// @notice Check if the given address is a member of this IPDAO
    function isMember(address _memberAddr) external view returns (bool) {
        return members[_memberAddr];
    }

    /// @notice Get the total account of members of this IPDAO
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }
}
