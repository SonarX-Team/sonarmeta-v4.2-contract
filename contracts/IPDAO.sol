// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Creation.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta IP DAO contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract IPDAO is Ownable, ReentrancyGuard {
    struct Submission {
        address submitter;
        uint256 weight; // Percentage weight%
    }

    Creation private creation;

    mapping(address => bool) private members;
    uint256 private memberCount;

    mapping(uint256 => Submission) private submissions;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a member has been added
    event MemberAdded(address indexed memberAddr);

    /// @notice Emitted when a member has been removed
    event MemberRemoved(address indexed memberAddr);

    /// @notice Emitted when a creation token is submitted
    event CreationSubmitted(
        uint256 indexed tokenId,
        address indexed submitter,
        uint256 weight
    );

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier onlyNotMember(address _memberAddr) {
        require(
            !members[_memberAddr],
            "The given address has been already a member. in this IP DAO."
        );
        _;
    }

    modifier onlyMember(address _memberAddr) {
        require(
            members[_memberAddr],
            "The given address is not a member in this IP DAO."
        );
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(address _creationImpAddr) Ownable(msg.sender) {
        initializeReentrancyGuard();

        creation = Creation(_creationImpAddr);
    }

    /// @notice Add a member to this IP DAO by its owner
    /// @param _memberAddr The member address to be added
    function addMember(address _memberAddr)
        external
        onlyOwner
        onlyNotMember(_memberAddr)
        nonReentrant
    {
        members[_memberAddr] = true;
        memberCount++;

        emit MemberAdded(_memberAddr);
    }

    /// @notice Remove a member from this IP DAO by its owner
    /// @param _memberAddr The member address to be removed
    function removeMember(address _memberAddr)
        external
        onlyOwner
        onlyMember(_memberAddr)
        nonReentrant
    {
        delete members[_memberAddr];
        memberCount--;

        emit MemberRemoved(_memberAddr);
    }

    /// @notice Submit creation/component token to a TBA
    /// Postcondition: Must call submitCreation in SonarMeta after
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

        Submission storage submission = submissions[_creationId];

        submission.submitter = msg.sender;
        submission.weight = _weight;

        creation.safeTransferFrom(msg.sender, _to, _creationId);

        emit CreationSubmitted(_creationId, msg.sender, _weight);
    }

    /// @notice Method for withdrawing proceeds to member
    /// @param _tbaAddr Address of a TBA owned by this IP DAO
    function withdrawProceeds(address _tbaAddr)
        external
        onlyMember(msg.sender)
        nonReentrant
    {
        // TODO：需要一个tba实现检查给定TBA的owner是不是这个IP DAO
        // address owner = tba.owner(_tbaAddr);

        // require(
        //     owner == address(this),
        //     "Withdraw can only be done with a TBA owned by this IP DAO."
        // );

        uint256[] memory tokensOwnedByTBA = creation.getTokenIds(_tbaAddr);
        uint256 totalWeight;

        for (uint256 i = 0; i < tokensOwnedByTBA.length; i++) {
            Submission memory submission = submissions[tokensOwnedByTBA[i]];

            if (submission.submitter == msg.sender)
                totalWeight += submission.weight;
        }

        uint256 proceed = _tbaAddr.balance * totalWeight;

        require(proceed > 0, "No proceed can be withdrawed");

        // TODO：需要前置条件，即控制此合约能够控制_tbaAddr.balance
        (bool success, ) = payable(msg.sender).call{value: proceed}("");

        require(success, "Transfer failed");
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
