// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Creation.sol";
import "./Authorization.sol";
import "./LockingVault.sol";
import "./IpDao.sol";

import "./utils/Governance.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is Ownable, ReentrancyGuard {
    struct Node {
        bool isSigned; // If this node is signed to use the SonarMeta protocol
        uint256 tokenId; // The tokenID of the corresponding creation
        mapping(address => bool) derivatives; // All derivatives of this node
        uint256 derivativeCount; // The amount of derivatives of this node
        uint256 nodeValue; // The value of this node
    }

    // Track node infos, token-bound account address => node info
    mapping(address => Node) private s_nodes;
    // Track all IP DAOs deployed by the SonarMeta protocol
    mapping(address => bool) private s_ipDaos;
    // SonarMeta ROI in percentage
    uint256 private s_rateOfReturn = 5; // SonarMeta ROI in percentage

    Governance private s_governance;
    Creation private s_creation;
    Authorization private s_authorization;
    LockingVault private s_vault;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emit when a node is signed to use the SonarMeta protocol
    event NodeSigned(address indexed nodeAddr);

    /// @notice Emit when a node is activated
    event NodeActivated(address indexed nodeAddr);

    /// @notice Emit when an application is accepted
    event ApplictaionAccepted(
        uint256 indexed tokenId,
        address indexed original,
        address indexed derivative,
        uint256 amount
    );

    /// @notice Emit when authorization confirmed
    event AuthorizationConfirmed(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /// @notice Emit when authorization cancelled
    event AuthorizationCancelled(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /// @notice Emit when an IP DAO is deployed
    event IpDaoDeployed(address indexed ipDaoAddr, address indexed owner);

    /// @notice Emit when the SonarMeta ROI is changed
    event SonarMetaRoiChanged(uint256 rateOfReturn);

    ///////////////////////   Errors   ///////////////////////

    error NodeNotSigned(address nodeAddr);
    error AuthorizationMustBeIssuedByOriginal(
        address nodeAddr,
        uint256 tokenId
    );
    error NodeIsNotDerivative(address original, address derivative);
    error NodeIsDerivative(address original, address derivative);
    error NotApprovedForSonarMetaProtocol(address original);
    error RoiMustBePercentage(uint256 rateOfReturn);

    /////////////////////   Modifiers   //////////////////////

    modifier onlySignedNode(address _nodeAddr) {
        if (!s_nodes[_nodeAddr].isSigned) revert NodeNotSigned(_nodeAddr);
        _;
    }

    modifier onlyOriginal(address _nodeAddr, uint256 _tokenId) {
        if (!(s_nodes[_nodeAddr].tokenId == _tokenId))
            revert AuthorizationMustBeIssuedByOriginal(_nodeAddr, _tokenId);
        _;
    }

    modifier onlyDerivative(address _original, address _derivative) {
        if (!s_nodes[_original].derivatives[_derivative])
            revert NodeIsNotDerivative(_original, _derivative);
        _;
    }

    modifier onlyNotDerivative(address _original, address _derivative) {
        if (s_nodes[_original].derivatives[_derivative])
            revert NodeIsDerivative(_original, _derivative);
        _;
    }

    ///////////////////   Main Functions   ///////////////////

    constructor(
        address _creationImpAddr,
        address _authorizationImpAddr,
        address _lockingVaultImpAddr
    ) Ownable(msg.sender) {
        initializeReentrancyGuard();

        s_governance = Governance(owner());
        s_creation = Creation(_creationImpAddr);
        s_authorization = Authorization(_authorizationImpAddr);
        s_vault = LockingVault(_lockingVaultImpAddr);
    }

    /// @notice Mint a new creation/component token
    /// @param _to The account the owner of the new creation/component token
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to) external nonReentrant returns (uint256) {
        uint256 tokenId = s_creation.mint(_to);

        return tokenId;
    }

    /// @notice A Node signs to use the SonarMeta protocol
    /// @param _nodeAddr The token-bound account address of this node that wants to sign
    /// @param _tokenId The creation tokenID corresponding to this node
    function signNodeToUse(
        address _nodeAddr,
        uint256 _tokenId
    ) external nonReentrant {
        Node storage node = s_nodes[_nodeAddr];

        node.isSigned = true;
        node.tokenId = _tokenId;

        emit NodeSigned(_nodeAddr);
    }

    /// @notice Mint corresponding authorization tokens to make the node a original
    /// @param _nodeAddr The token-bound account address of this node that wants to activate authorization
    /// @param _tokenId The authorization tokenID corresponding to this node
    /// @param _maxSupply The maximum limit of this authorization token, e.g. 10,000,000
    function activateNode(
        address _nodeAddr,
        uint256 _tokenId,
        uint256 _maxSupply
    )
        external
        onlySignedNode(_nodeAddr)
        onlyOriginal(_nodeAddr, _tokenId)
        nonReentrant
    {
        s_authorization.initialClaim(_nodeAddr, _tokenId, _maxSupply);

        emit NodeActivated(_nodeAddr);
    }

    /// @notice Accept a first-time application from an inclined derivative by original
    /// msg.sender must be the original node
    /// @param _tokenId The tokenID of the original node
    /// @param _derivative The node which is going to be applied
    /// @param _amount The amount the original node wants to give
    function acceptApplication(
        uint256 _tokenId,
        address _derivative,
        uint256 _amount
    )
        external
        onlySignedNode(msg.sender)
        onlySignedNode(_derivative)
        onlyOriginal(msg.sender, _tokenId)
        onlyNotDerivative(msg.sender, _derivative)
        nonReentrant
    {
        s_vault.lockToContribute(_tokenId, _derivative, _amount);

        if (!s_authorization.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForSonarMetaProtocol(msg.sender);

        s_authorization.safeTransferFrom(
            msg.sender,
            address(s_vault),
            _tokenId,
            _amount,
            ""
        );

        emit ApplictaionAccepted(_tokenId, msg.sender, _derivative, _amount);
    }

    /// @notice After locking, the derivative node confirms the authorization
    /// msg.sender is the derivative node itself
    /// @param _original The node which will issue authorization
    /// @param _tokenId The tokenID of the creation token
    function confirmAuthorization(
        address _original,
        uint256 _tokenId
    )
        external
        onlySignedNode(_original)
        onlySignedNode(msg.sender)
        onlyOriginal(_original, _tokenId)
        onlyNotDerivative(_original, msg.sender)
        nonReentrant
    {
        s_vault.releaseLocking(_tokenId, msg.sender, address(this));

        Node storage node = s_nodes[_original];

        node.derivatives[msg.sender] = true;
        node.derivativeCount++;

        emit AuthorizationConfirmed(_tokenId, _original, msg.sender);
    }

    /// @notice During locking, the original can cancel the authorization for some reason
    /// msg.sender must be the original node
    /// @param _derivative The node which will be cancelled
    /// @param _tokenId The tokenID of the creation token
    function cancelAuthorization(
        address _derivative,
        uint256 _tokenId
    )
        external
        onlySignedNode(msg.sender)
        onlySignedNode(_derivative)
        onlyOriginal(msg.sender, _tokenId)
        onlyNotDerivative(msg.sender, _derivative)
        nonReentrant
    {
        s_vault.returnLocking(_tokenId, msg.sender, _derivative);

        emit AuthorizationCancelled(_tokenId, msg.sender, _derivative);
    }

    /// @notice Deploy a new IP DAO contract
    /// @param _creationImpAddr the address of the creation contract
    /// @return the address of the new IP DAO contract
    function deployIpDao(
        address _creationImpAddr
    ) external nonReentrant returns (address) {
        IpDao ipDao = new IpDao(msg.sender, _creationImpAddr);
        address ipDaoAddr = address(ipDao);

        s_ipDaos[ipDaoAddr] = true;

        emit IpDaoDeployed(ipDaoAddr, msg.sender);

        return ipDaoAddr;
    }

    /// @notice Reset the SonarMeta ROI for the SonarMeta protocol
    /// @param _rateOfReturn the ROI you want to set
    function setSonarMetaRoi(
        uint256 _rateOfReturn
    ) external onlyOwner nonReentrant {
        if (_rateOfReturn < 0 || _rateOfReturn > 100)
            revert RoiMustBePercentage(_rateOfReturn);

        s_rateOfReturn = _rateOfReturn;

        emit SonarMetaRoiChanged(_rateOfReturn);
    }

    //////////////////   Getter Functions   //////////////////

    /// @notice Check if a node is signed
    function isNodeSigned(address _nodeAddr) external view returns (bool) {
        return s_nodes[_nodeAddr].isSigned;
    }

    /// @notice Check if a node is an original to a tokenID
    function isOriginal(
        address _original,
        uint256 _tokenId
    ) external view returns (bool) {
        return s_nodes[_original].tokenId == _tokenId;
    }

    /// @notice Check if a node is another node's derivative
    function isDerivativeByAddress(
        address _original,
        address _derivative
    ) external view returns (bool) {
        return s_nodes[_original].derivatives[_derivative];
    }

    /// @notice Check if a node is another node's derivative
    function isDerivativeByTokenId(
        uint256 _tokenId,
        address _derivative
    ) external view returns (bool) {
        address original = s_creation.ownerOf(_tokenId);
        return s_nodes[original].derivatives[_derivative];
    }

    /// @notice Get the total amount of derivatives of an original
    function getDerivativeCount(
        address _nodeAddr
    ) external view returns (uint256) {
        return s_nodes[_nodeAddr].derivativeCount;
    }

    /// @notice Get the nodeValue of a node
    function getNodeValue(address _nodeAddr) external view returns (uint256) {
        return s_nodes[_nodeAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return s_ipDaos[_ipDaoAddr];
    }

    /// @notice Get the ROI of the SonarMeta protocol
    function getSonarMetaRoi() external view returns (uint256) {
        return s_rateOfReturn;
    }
}
