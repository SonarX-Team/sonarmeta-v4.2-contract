// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Creation.sol";
import "./Authorization.sol";
import "./IpDao.sol";
import "./utils/Governance.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Counters.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is ERC1155Holder, Ownable, ReentrancyGuard {
    /// @notice TBA information struct
    struct Tba {
        bool isSigned; // If this TBA is signed to use SonarMeta
        uint256 tokenId; // The tokenID of the corresponding creation
        mapping(address => bool) holders; // All holder TBAs of this TBA
        uint256 holderCount; // The amount of holder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    // Track TBA infos, TBA address => TBA info
    mapping(address => Tba) private s_tbas;
    // Track locking tokens of each original tokenID - derivative pair
    mapping(uint256 => mapping(address => uint256)) private s_lockings;
    // Track all IP DAOs deployed by SonarMeta
    mapping(address => bool) private s_ipDaos;

    address private s_creationImpAddr;

    Governance private s_governance;
    Creation private s_creation;
    Authorization private s_authorization;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a TBA is signed to use SonarMeta
    event TbaSigned(address indexed tbaAddr);

    /// @notice Emitted when authorized
    event Authorized(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /// @notice Emitted when an IP DAO is deployed
    event IpDaoDeployed(address indexed ipDaoAddr, address indexed owner);

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier onlySignedTba(address _tbaAddr) {
        require(
            s_tbas[_tbaAddr].isSigned,
            "Address provided must be a signed TBA towards SonarMeta."
        );
        _;
    }

    modifier onlyIssuer(address _tbaAddr, uint256 _tokenId) {
        require(
            s_tbas[_tbaAddr].tokenId == _tokenId,
            "Authorization token must be issued by its corresponding creation's TBA."
        );
        _;
    }

    modifier onlyHolder(address _issuer, address _holder) {
        require(
            s_tbas[_issuer].holders[_holder],
            "This TBA has not been authorized (a holder) yet."
        );
        _;
    }

    modifier onlyNotHolder(address _issuer, address _holder) {
        require(
            !s_tbas[_issuer].holders[_holder],
            "This TBA has been already (a holder) authorized."
        );
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(
        address _creationImpAddr,
        address _authorizationImpAddr
    ) Ownable(msg.sender) {
        initializeReentrancyGuard();

        s_governance = Governance(owner());
        s_creation = Creation(_creationImpAddr);
        s_authorization = Authorization(_authorizationImpAddr);

        s_creationImpAddr = _creationImpAddr;
    }

    /// @notice Mint a new creation/component token
    /// @param _to The account the owner of the new creation/component token
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to) external nonReentrant returns (uint256) {
        uint256 tokenId = s_creation.mint(_to);

        return tokenId;
    }

    /// @notice A TBA signs to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function signNode(
        address _tbaAddr,
        uint256 _tokenId
    ) external nonReentrant {
        Tba storage tba = s_tbas[_tbaAddr];
        tba.isSigned = true;

        s_tbas[_tbaAddr].tokenId = _tokenId;

        emit TbaSigned(_tbaAddr);
    }

    /// @notice Mint corresponding authorization tokens to make the node a issuer
    /// @param _tbaAddr The TBA address wants to activate authorization
    /// @param _tokenId The creation tokenID corresponding to this TBA
    /// @param _maxSupply The maximum limit of this authorization token, e.g. 10,000,000
    function activateNode(
        address _tbaAddr,
        uint256 _tokenId,
        uint256 _maxSupply
    )
        external
        onlySignedTba(_tbaAddr)
        onlyIssuer(_tbaAddr, _tokenId)
        nonReentrant
    {
        s_authorization.initialClaim(_tbaAddr, _tokenId, _maxSupply);
    }

    /// @notice Accept a first-time application from a derivative node
    /// @param _derivative The TBA which is going to apply
    /// @param _tokenId The tokenID of the original node
    /// @param _amount The amount the original node wants to give
    function acceptApplication(
        address _derivative,
        uint256 _tokenId,
        uint256 _amount
    ) external onlySignedTba(_derivative) nonReentrant {
        s_lockings[_tokenId][_derivative] = _amount;
    }

    /// @notice Authorize from an original to a derivative / Accept the derivative
    /// @param _original The TBA which will issue the authorization token
    /// @param _derivative The TBA which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @return The total holder amount of the creation
    function authorize(
        address _original,
        address _derivative,
        uint256 _tokenId
    )
        external
        onlySignedTba(_original)
        onlySignedTba(_derivative)
        onlyIssuer(_original, _tokenId)
        onlyNotHolder(_original, _derivative)
        nonReentrant
        returns (uint256)
    {
        require(
            s_authorization.isApprovedForAll(msg.sender, address(this)),
            "Not approved for SonarMeta protocol."
        );

        uint256 amount = s_lockings[_tokenId][_derivative];
        require(amount > 0, "Cannot authorize a TBA without application.");

        Tba storage tba = s_tbas[_original];

        s_authorization.safeTransferFrom(
            _original,
            _derivative,
            _tokenId,
            (amount * 19) / 20, // 95% for the derivative.
            ""
        );
        s_authorization.safeTransferFrom(
            _original,
            address(this),
            _tokenId,
            (amount * 1) / 20, // 5% for SonarMeta protocol.
            ""
        );

        tba.holders[_derivative] = true;
        tba.holderCount++;

        emit Authorized(_tokenId, _original, _derivative);

        return tba.holderCount;
    }

    /// @notice Deploy a new IP DAO
    function deployIpDao() external nonReentrant returns (address) {
        IpDao ipDao = new IpDao(msg.sender, s_creationImpAddr);
        address ipDaoAddr = address(ipDao);

        s_ipDaos[ipDaoAddr] = true;

        emit IpDaoDeployed(ipDaoAddr, msg.sender);

        return ipDaoAddr;
    }

    /// @notice Method for withdrawing authorization tokens to SonarMeta owner
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

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Check if a TBA is signed
    function isTbaSigned(address _tbaAddr) external view returns (bool) {
        return s_tbas[_tbaAddr].isSigned;
    }

    /// @notice Check if a node is another node's derivative
    function isHolderByAddress(
        address _original,
        address _derivative
    )
        external
        view
        onlySignedTba(_original)
        onlySignedTba(_derivative)
        returns (bool)
    {
        return s_tbas[_original].holders[_derivative];
    }

    /// @notice Check if a node is another node's derivative
    function isHolderByTokenId(
        uint256 _tokenId,
        address _derivative
    ) external view onlySignedTba(_derivative) returns (bool) {
        address original = s_creation.ownerOf(_tokenId);
        return s_tbas[original].holders[_derivative];
    }

    /// @notice Get the total amount of holders of a TBA
    function getHolderCount(
        address _tbaAddr
    ) external view onlySignedTba(_tbaAddr) returns (uint256) {
        return s_tbas[_tbaAddr].holderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(
        address _tbaAddr
    ) external view onlySignedTba(_tbaAddr) returns (uint256) {
        return s_tbas[_tbaAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return s_ipDaos[_ipDaoAddr];
    }
}
