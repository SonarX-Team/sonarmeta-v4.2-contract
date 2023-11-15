// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./Creation.sol";
import "./Authorization.sol";
import "./IpDao.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Counters.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is Ownable, Storage, ReentrancyGuard {
    /// @notice TBA information struct
    struct Tba {
        bool isSigned; // If this TBA is signed to use SonarMeta
        uint256 tokenId; // The tokenID of the corresponding creation
        mapping(address => bool) stakeholders; // All Stakeholder TBAs of this TBA
        uint256 stakeholderCount; // The amount of stakeholder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    // Track TBA infos, TBA address => TBA info
    mapping(address => Tba) private tbas;
    // Track all IP DAOs deployed by SonarMeta
    mapping(address => bool) private ipDaos;

    address private creationImpAddr;

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

    /// @notice Emitted when contribution increased
    event Contributed(
        uint256 indexed tokenId,
        uint256 amount,
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
            tbas[_tbaAddr].isSigned,
            "Address provided must be a signed TBA towards SonarMeta."
        );
        _;
    }

    modifier onlyIssuer(address _tbaAddr, uint256 _tokenId) {
        require(
            tbas[_tbaAddr].tokenId == _tokenId,
            "Authorization token must be issued by its corresponding creation's TBA."
        );
        _;
    }

    modifier onlyHolder(address _host, address _holder) {
        require(
            tbas[_host].stakeholders[_holder],
            "This TBA has not been authorized (a stakeholder) yet."
        );
        _;
    }

    modifier onlyNotHolder(address _host, address _holder) {
        require(
            !tbas[_host].stakeholders[_holder],
            "This TBA has been already (a stakeholder) authorized."
        );
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(address _creationImpAddr, address _authorizationImpAddr)
        Ownable(msg.sender)
    {
        initializeReentrancyGuard();

        governance = Governance(owner());
        creation = Creation(_creationImpAddr);
        authorization = Authorization(_authorizationImpAddr);

        creationImpAddr = _creationImpAddr;
    }

    /// @notice Create a new creation/component token
    /// @param _to The account the owner of the new creation/component token
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to) external nonReentrant returns (uint256) {
        uint256 tokenId = creation.mint(_to);

        return tokenId;
    }

    /// @notice A TBA sign to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function signToUseSonarMeta(address _tbaAddr, uint256 _tokenId)
        external
        nonReentrant
    {
        Tba storage tba = tbas[_tbaAddr];
        tba.isSigned = true;

        tbas[_tbaAddr].tokenId = _tokenId;

        emit TbaSigned(_tbaAddr);
    }

    /// @notice Authorize from a TBA to another TBA (increase 1 contribution)
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @return The total stakeholder amount of the creation
    function authorize(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        onlySignedTba(_from)
        onlySignedTba(_to)
        onlyIssuer(_from, _tokenId)
        onlyNotHolder(_from, _to)
        nonReentrant
        returns (uint256)
    {
        Tba storage tba = tbas[_from];

        require(
            !tba.stakeholders[_to],
            "This TBA has been already authorized."
        );

        // Generate a new authorization token corresponding to this creation token
        // if this is the first time this creation token issues authorization
        authorization.authorize(_to, _tokenId, "");
        // With extra 10 bonus to SonarMeta
        authorization.increase(address(this), _tokenId, 10, "");

        tba.stakeholders[_to] = true;
        tba.stakeholderCount++;

        emit Authorized(_tokenId, _from, _to);

        return tba.stakeholderCount;
    }

    /// @notice Increase contribution from a TBA to another TBA
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @param _amount The contribution value that the minter wants to give
    /// @return The total contribution amount of _to
    function contribute(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    )
        external
        onlySignedTba(_from)
        onlySignedTba(_to)
        onlyIssuer(_from, _tokenId)
        onlyHolder(_from, _to)
        nonReentrant
        returns (uint256)
    {
        authorization.increase(_to, _tokenId, _amount, "");

        emit Contributed(_tokenId, _amount, _from, _to);

        return authorization.balanceOf(_to, _tokenId);
    }

    /// @notice Deploy a new IP DAO
    function deployIpDao() external nonReentrant returns (address) {
        IpDao ipDao = new IpDao(msg.sender, creationImpAddr);
        address ipDaoAddr = address(ipDao);

        ipDaos[ipDaoAddr] = true;

        emit IpDaoDeployed(ipDaoAddr, msg.sender);

        return ipDaoAddr;
    }

    /// @notice Method for withdrawing authorization tokens to SonarMeta owner
    function withdraw() external onlyOwner nonReentrant {
        uint256 totalSupply = creation.totalSupply();

        uint256[] memory ids = new uint256[](totalSupply);
        uint256[] memory amounts = new uint256[](totalSupply);

        for (uint256 i = 1; i <= totalSupply; i++) {
            ids[i] = i;
            amounts[i] = authorization.balanceOf(address(this), i);
        }

        authorization.safeBatchTransferFrom(
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
        return tbas[_tbaAddr].isSigned;
    }

    /// @notice Check if a TBA is another TBA's stakeholder
    function isStakeholder(address _stakeholderAddr, address _tbaAddr)
        external
        view
        onlySignedTba(_stakeholderAddr)
        onlySignedTba(_tbaAddr)
        returns (bool)
    {
        return tbas[_tbaAddr].stakeholders[_stakeholderAddr];
    }

    /// @notice Get the total amount of stakeholders of a TBA
    function getStakeholderCount(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return tbas[_tbaAddr].stakeholderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return tbas[_tbaAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return ipDaos[_ipDaoAddr];
    }
}
