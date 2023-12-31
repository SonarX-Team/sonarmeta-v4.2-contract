// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SonarMeta.sol";
import "./Authorization.sol";

import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta locking vault contract for authorization tokens
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract LockingVault is ERC1155Holder, Ownable, ReentrancyGuard {
    uint256 public constant LOCK_DURATION = 30 days;

    struct LockingInfo {
        uint256 amount;
        uint256 lockTimestamp;
    }

    // Track locking tokens of each original tokenID - derivative pair
    mapping(uint256 => mapping(address => LockingInfo)) private s_lockings;

    Authorization private s_authorization;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emit when a locking is set up
    event AuthorizationTokenLocked(
        uint256 indexed tokenId,
        address indexed derivative,
        uint256 amount
    );

    /// @notice Emit when a locking is released
    event LockingReleased(
        uint256 indexed tokenId,
        address indexed derivative,
        uint256 amount
    );

    /// @notice Emit when a locking is returned
    event LockingReturned(
        uint256 indexed tokenId,
        address indexed derivative,
        uint256 amount
    );

    ///////////////////////   Errors   ///////////////////////
    error LockingAmountMustBeAboveZero();
    error LockingAlreadyExists();
    error NoLockings();
    error LockingDurationNotReached();
    error LockingDurationHasExpired();

    ///////////////////   Main Functions   ///////////////////

    constructor(
        address _initialOwner,
        address _authorizationImpAddr
    ) Ownable(_initialOwner) {
        initializeReentrancyGuard();

        s_authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice First-time application lock to contribute
    /// @param _tokenId The tokenID of the original node
    /// @param _derivative The node which is going to apply
    /// @param _amount The amount the original node wants to give
    function lockToContribute(
        uint256 _tokenId,
        address _derivative,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        if (_amount == 0) revert LockingAmountMustBeAboveZero();

        LockingInfo storage lockingInfo = s_lockings[_tokenId][_derivative];

        if (lockingInfo.amount > 0) revert LockingAlreadyExists();

        s_lockings[_tokenId][_derivative] = LockingInfo({
            amount: _amount,
            lockTimestamp: block.timestamp
        });

        emit AuthorizationTokenLocked(_tokenId, _derivative, _amount);
    }

    /// @notice Release locked tokens after locking duration
    /// @param _tokenId The tokenID of the original node
    /// @param _derivative The node which is going to become a derivative
    /// @param _sonarmetaImpAddr Address of the SonarMeta main contract
    function releaseLocking(
        uint256 _tokenId,
        address _derivative,
        address _sonarmetaImpAddr
    ) external onlyOwner nonReentrant {
        LockingInfo storage lockingInfo = s_lockings[_tokenId][_derivative];

        if (lockingInfo.amount == 0) revert NoLockings();
        if (block.timestamp < lockingInfo.lockTimestamp + LOCK_DURATION)
            revert LockingDurationNotReached();

        uint256 amountToRelease = lockingInfo.amount;
        lockingInfo.amount = 0;

        SonarMeta sonarmeta = SonarMeta(_sonarmetaImpAddr);

        s_authorization.safeTransferFrom(
            address(this),
            _derivative,
            _tokenId,
            (amountToRelease * (100 - sonarmeta.getSonarMetaRoi())) / 100,
            ""
        );
        s_authorization.safeTransferFrom(
            address(this),
            owner(),
            _tokenId,
            (amountToRelease * sonarmeta.getSonarMetaRoi()) / 100,
            ""
        );

        emit LockingReleased(_tokenId, _derivative, amountToRelease);
    }

    /// @notice Return locked tokens before reaching deadline
    /// @param _tokenId The tokenID of the original node
    /// @param _original The node which will receive the tokens
    /// @param _derivative The node which is an inclined derivative
    function returnLocking(
        uint256 _tokenId,
        address _original,
        address _derivative
    ) external onlyOwner nonReentrant {
        LockingInfo storage lockingInfo = s_lockings[_tokenId][_derivative];

        if (lockingInfo.amount == 0) revert NoLockings();
        if (block.timestamp >= lockingInfo.lockTimestamp + LOCK_DURATION)
            revert LockingDurationHasExpired();

        uint256 amountToReturn = lockingInfo.amount;
        lockingInfo.amount = 0;

        s_authorization.safeTransferFrom(
            address(this),
            _original,
            _tokenId,
            amountToReturn,
            ""
        );

        emit LockingReturned(_tokenId, _derivative, amountToReturn);
    }

    //////////////////   Getter Functions   //////////////////

    /// @notice Get locking amount and remaining locking time for a given derivative and tokenId
    /// @param _tokenId The tokenID of the original node
    /// @param _derivative The node which is going to become a derivative
    /// @return Locking amount, remaining locking time in seconds
    function getLockingInfo(
        uint256 _tokenId,
        address _derivative
    ) external view returns (uint256, uint256) {
        LockingInfo memory lockingInfo = s_lockings[_tokenId][_derivative];

        if (lockingInfo.amount == 0) return (0, 0);

        uint256 elapsedTime = block.timestamp - lockingInfo.lockTimestamp;
        uint256 remainingTime = 0;

        if (elapsedTime < LOCK_DURATION)
            remainingTime = LOCK_DURATION - elapsedTime;

        return (lockingInfo.amount, remainingTime);
    }
}
