// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Creation.sol";
import "./Authorization.sol";
import "./LockingVault.sol";
import "./IpDao.sol";
import "./utils/Governance.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is ERC1155Holder, Ownable, ReentrancyGuard {
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

    Governance private s_governance;
    Creation private s_creation;
    Authorization private s_authorization;
    LockingVault private s_vault;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emitted when a node is signed to use the SonarMeta protocol
    event NodeSigned(address indexed nodeAddr);

    /// @notice Emitted when authorized
    event Authorized(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /// @notice Emitted when an IP DAO is deployed
    event IpDaoDeployed(address indexed ipDaoAddr, address indexed owner);

    ///////////////////////   Errors   ///////////////////////

    error NodeNotSigned(address nodeAddr);
    error AuthorizationMustBeIssuedByOriginal(
        address nodeAddr,
        uint256 tokenId
    );
    error NodeIsNotDerivative(address original, address derivative);
    error NodeIsDerivative(address original, address derivative);
    error NotApprovedForSonarMetaProtocol();

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

        s_nodes[_nodeAddr].tokenId = _tokenId;

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
    }

    /// @notice Accept a first-time application from a derivative node
    /// @param _tokenId The tokenID of the original node
    /// @param _derivative The node which is going to be applied
    /// @param _amount The amount the original node wants to give
    function acceptApplication(
        uint256 _tokenId,
        address _derivative,
        uint256 _amount
    ) external onlySignedNode(_derivative) nonReentrant {
        s_vault.lockToContribute(_tokenId, _derivative, _amount);
    }

    /// @notice Authorize from an original to a derivative / Accept the derivative
    /// @param _original The node which will issue the authorization token
    /// @param _derivative The node which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @return The total derivative amount of the creation
    function authorize(
        address _original,
        address _derivative,
        uint256 _tokenId
    )
        external
        onlySignedNode(_original)
        onlySignedNode(_derivative)
        onlyOriginal(_original, _tokenId)
        onlyNotDerivative(_original, _derivative)
        nonReentrant
        returns (uint256)
    {
        if (!s_authorization.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForSonarMetaProtocol();

        s_vault.releaseLocking(_tokenId, _derivative, address(this));

        Node storage node = s_nodes[_original];

        node.derivatives[_derivative] = true;
        node.derivativeCount++;

        emit Authorized(_tokenId, _original, _derivative);

        return node.derivativeCount;
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

    /// @notice Method for withdrawing authorization tokens to the admin
    function withdraw() external onlyOwner nonReentrant {
        uint256 totalSupply = s_creation.totalSupply();

        uint256[] memory ids = new uint256[](totalSupply);
        uint256[] memory amounts = new uint256[](totalSupply);

        for (uint256 i = 1; i <= totalSupply; i++) {
            ids[i] = i;
            amounts[i] = s_authorization.balanceOf(address(this), i);
        }

        s_authorization.safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amounts,
            ""
        );
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
    )
        external
        view
        onlySignedNode(_original)
        onlySignedNode(_derivative)
        returns (bool)
    {
        return s_nodes[_original].derivatives[_derivative];
    }

    /// @notice Check if a node is another node's derivative
    function isDerivativeByTokenId(
        uint256 _tokenId,
        address _derivative
    ) external view onlySignedNode(_derivative) returns (bool) {
        address original = s_creation.ownerOf(_tokenId);
        return s_nodes[original].derivatives[_derivative];
    }

    /// @notice Get the total amount of derivatives of an original
    function getDerivativeCount(
        address _nodeAddr
    ) external view onlySignedNode(_nodeAddr) returns (uint256) {
        return s_nodes[_nodeAddr].derivativeCount;
    }

    /// @notice Get the nodeValue of a node
    function getNodeValue(
        address _nodeAddr
    ) external view onlySignedNode(_nodeAddr) returns (uint256) {
        return s_nodes[_nodeAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return s_ipDaos[_ipDaoAddr];
    }
}
