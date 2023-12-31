// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Marketplace.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta business protocol contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Business is ReentrancyGuard {
    struct BusinessInfo {
        bool isSigned; // If this business is signed to use the Business protocol
        mapping(address => bool) nodes; // All nodes that use this business
        uint256 nodeCount; // The amount of nodes/users of this business
        uint256 rateOfReturn; // The ROI of this business in percent
        uint256 proceeds; // The proceeds that this business can withdraw
    }

    // Track all business, business owner => business info
    mapping(address => BusinessInfo) s_businesses;

    address private s_marketplaceImpAddr;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emit when a business is signed to use the Business protocol
    event BusinessSigned(address indexed businessAddr);

    /// @notice Emit when the Business ROI is changed
    event BusinessRoiChanged(
        address indexed businessAddr,
        uint256 rateOfReturn
    );

    /// @notice Emit when the a node is added to a Business
    event NodeAdded(address indexed businessAddr, address indexed node);

    ///////////////////////   Errors   ///////////////////////

    error BusinessNotSigned(address businessAddr);
    error RoiMustBePercentage(uint256 rateOfReturn);
    error SenderIsNotMarketplace(address marketplaceImpAddr);
    error NoProceeds(address businessAddr);

    /////////////////////   Modifiers   //////////////////////

    modifier onlySignedBusiness(address _businessAddr) {
        if (!s_businesses[_businessAddr].isSigned)
            revert BusinessNotSigned(_businessAddr);
        _;
    }

    modifier onlyMarketplace(address _sender) {
        if (s_marketplaceImpAddr != _sender)
            revert SenderIsNotMarketplace(_sender);
        _;
    }

    ///////////////////   Main Functions   ///////////////////

    constructor(address _marketplaceImpAddr) {
        s_marketplaceImpAddr = _marketplaceImpAddr;
    }

    /// @notice A business signs to use the Business protocol
    /// msg.sender is the business owner address that wants to sign
    /// @param _rateOfReturn The ROI that the business owner wants to apply
    function signBusinessToUse(uint256 _rateOfReturn) external nonReentrant {
        BusinessInfo storage info = s_businesses[msg.sender];

        if (_rateOfReturn < 0 || _rateOfReturn > 100)
            revert RoiMustBePercentage(_rateOfReturn);

        info.isSigned = true;
        info.rateOfReturn = _rateOfReturn;

        emit BusinessSigned(msg.sender);
        emit BusinessRoiChanged(msg.sender, _rateOfReturn);
    }

    /// @notice A Business resets its ROI
    /// msg.sender is the business owner address that wants to sign
    /// @param _rateOfReturn The ROI that the business owner wants to apply
    function setBusinessRoi(
        uint256 _rateOfReturn
    ) external onlySignedBusiness(msg.sender) nonReentrant {
        if (_rateOfReturn < 0 || _rateOfReturn > 100)
            revert RoiMustBePercentage(_rateOfReturn);

        s_businesses[msg.sender].rateOfReturn = _rateOfReturn;

        emit BusinessRoiChanged(msg.sender, _rateOfReturn);
    }

    /// @notice A Node adds itself to a business
    /// msg.sender is the node token-bound account address that wants to add
    /// @param _businessAddr The business owner address
    function addNodeToBusiness(
        address _businessAddr
    ) external onlySignedBusiness(_businessAddr) nonReentrant {
        BusinessInfo storage info = s_businesses[_businessAddr];

        info.nodes[msg.sender] = true;
        info.nodeCount++;

        emit NodeAdded(_businessAddr, msg.sender);
    }

    /// @notice Increase businesses' proceeds after a transaction in Marketplace
    /// msg.sender must be the Marketplace contract
    /// The "for-loop" is not an ideal implementation,
    /// but let's assume a node won't engage in too much business for now
    /// @param _businessAddrs The addresses of the related businesses
    /// @param _businessFees The fees of the related businesses
    function increaseProceeds(
        address[] memory _businessAddrs,
        uint256[] memory _businessFees
    ) external onlyMarketplace(msg.sender) nonReentrant {
        for (uint256 i = 0; i < _businessAddrs.length; i++)
            s_businesses[_businessAddrs[i]].proceeds += _businessFees[i];
    }

    /// @notice Method for withdrawing authorization tokens to a business
    /// msg.sender must be a business
    function withdrawProceeds()
        external
        onlySignedBusiness(msg.sender)
        nonReentrant
    {
        uint256 proceeds = s_businesses[msg.sender].proceeds;

        if (proceeds <= 0) revert NoProceeds(msg.sender);

        s_businesses[msg.sender].proceeds = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    //////////////////   Getter Functions   //////////////////

    /// @notice Check if a business is signed
    function isBusinessSigned(
        address _businessAddr
    ) external view returns (bool) {
        return s_businesses[_businessAddr].isSigned;
    }

    /// @notice Get a business ROI
    function getBusinessRoi(
        address _businessAddr
    ) external view returns (uint256) {
        return s_businesses[_businessAddr].rateOfReturn;
    }
}
