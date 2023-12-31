// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Creation.sol";

import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta IP DAO contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract IpDao is ERC721Holder, Ownable, ReentrancyGuard {
    struct Submission {
        address submitter;
        uint256 weight; // Percentage weight%
    }

    Creation private s_creation;

    mapping(address => bool) private s_members;
    uint256 private s_memberCount;

    mapping(uint256 => Submission) private s_submissions;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emit when a member has been added
    event MemberAdded(address indexed memberAddr);

    /// @notice Emit when a member has been removed
    event MemberRemoved(address indexed memberAddr);

    /// @notice Emit when a creation token is submitted
    event CreationSubmitted(
        uint256 indexed tokenId,
        address indexed submitter,
        uint256 weight
    );

    /////////////////////   Modifiers   //////////////////////

    modifier onlyNotMember(address _memberAddr) {
        require(
            !s_members[_memberAddr],
            "The given address has been already a member. in this IP DAO."
        );
        _;
    }

    modifier onlyMember(address _memberAddr) {
        require(
            s_members[_memberAddr],
            "The given address is not a member in this IP DAO."
        );
        _;
    }

    ///////////////////   Main Functions   ///////////////////

    constructor(
        address _initialOwner,
        address _creationImpAddr
    ) Ownable(_initialOwner) {
        initializeReentrancyGuard();

        s_creation = Creation(_creationImpAddr);

        s_members[_initialOwner] = true;
        s_memberCount++;
    }

    /// @notice Add a member to this IP DAO by its owner
    /// @param _memberAddr The member address to be added
    function addMember(
        address _memberAddr
    ) external onlyOwner onlyNotMember(_memberAddr) nonReentrant {
        s_members[_memberAddr] = true;
        s_memberCount++;

        emit MemberAdded(_memberAddr);
    }

    /// @notice Remove a member from this IP DAO by its owner
    /// @param _memberAddr The member address to be removed
    function removeMember(
        address _memberAddr
    ) external onlyOwner onlyMember(_memberAddr) nonReentrant {
        delete s_members[_memberAddr];
        s_memberCount--;

        emit MemberRemoved(_memberAddr);
    }

    /// @notice Submit creation/component token to a TBA
    /// @param _to The destination TBA address (Must be a TBA)
    /// @param _creationId The tokenID of the creation/component token
    /// @param _weight The weight that set to this submission
    function submitCreation(
        address _to,
        uint256 _creationId,
        uint256 _weight
    ) external onlyMember(msg.sender) nonReentrant {
        // TODO：需要一个tba实现检查给定TBA的owner是不是这个IP DAO
        // address owner = tba.owner(_to);

        // require(
        //     owner == address(this),
        //     "Submission can only be done with a TBA owned by this IP DAO."
        // );

        Submission storage submission = s_submissions[_creationId];

        submission.submitter = msg.sender;
        submission.weight = _weight;

        s_creation.safeTransferFrom(msg.sender, _to, _creationId);

        emit CreationSubmitted(_creationId, msg.sender, _weight);
    }

    /// @notice Method for withdrawing proceeds to member
    /// @param _tbaAddr Address of a TBA owned by this IP DAO
    function withdrawProceeds(
        address _tbaAddr
    ) external onlyMember(msg.sender) nonReentrant {
        // TODO：需要一个tba实现检查给定TBA的owner是不是这个IP DAO
        // address owner = tba.owner(_tbaAddr);

        // require(
        //     owner == address(this),
        //     "Withdraw can only be done with a TBA owned by this IP DAO."
        // );

        uint256[] memory tokensOwnedByTba = s_creation.getTokenIds(_tbaAddr);
        uint256 totalWeight;

        for (uint256 i = 0; i < tokensOwnedByTba.length; i++) {
            Submission memory submission = s_submissions[tokensOwnedByTba[i]];

            if (submission.submitter == msg.sender)
                totalWeight += submission.weight;
        }

        uint256 proceed = _tbaAddr.balance * totalWeight;

        require(proceed > 0, "No proceed can be withdrawed");

        // TODO：需要前置条件，即控制此合约能够控制_tbaAddr.balance
        (bool success, ) = payable(msg.sender).call{value: proceed}("");

        require(success, "Transfer failed");
    }

    //////////////////   Getter Functions   //////////////////

    /// @notice Check if the given address is a member of this IP DAO
    function isMember(address _memberAddr) external view returns (bool) {
        return s_members[_memberAddr];
    }

    /// @notice Get the total account of members of this IP DAO
    function getMemberCount() external view returns (uint256) {
        return s_memberCount;
    }
}
