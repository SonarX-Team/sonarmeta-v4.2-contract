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
        mapping(address => bool) stakeholders; // All Stakeholder TBAs of this TBA
        uint256 stakeholderCount; // The amount of stakeholder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    // Track TBA infos, TBA address => TBA info
    mapping(address => Tba) private Tbas;
    // Track minters of authorization tokens, tokenID => TBA address
    mapping(uint256 => address) private authorizationMinters;
    // Track all IP DAOs deployed by SonarMeta
    mapping(address => bool) private ipDaos;

    address private creationImpAddr;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a TBA is signed to use SonarMeta
    event TbaSigned(address indexed tbaAddr);

    /// @notice Emitted when authorization tokens are minted
    event AuthorizationMinted(
        uint256 indexed authorizationId,
        address indexed tbaAddr
    );

    /// @notice Emitted when authorized
    event Authorized(
        uint256 indexed authorizationId,
        address indexed from,
        address indexed to
    );

    /// @notice Emitted when contribution increased
    event ContributionIncreased(
        uint256 indexed authorizationId,
        uint256 amount,
        address indexed from,
        address indexed to
    );

    /// @notice Emitted when an IP DAO is deployed
    event IpDaoDeployed(address indexed ipDaoAddr);

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier onlySignedTba(address _tbaAddr) {
        require(
            Tbas[_tbaAddr].isSigned,
            "Address provided must be a signed TBA towards SonarMeta."
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

    /// @notice A TBA sign to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    function signToUseSonarMeta(address _tbaAddr) external nonReentrant {
        Tba storage tba = Tbas[_tbaAddr];
        tba.isSigned = true;

        emit TbaSigned(_tbaAddr);
    }

    /// @notice Create a new creation/component token
    /// Currently in the demo version, every component of a co-creation MUST be a SonarMeta creation
    /// because we only use these components to calculate the proceeds of every co-creation member
    /// @param _to The account the owner of the new creation/component token
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to) external nonReentrant returns (uint256) {
        uint256 tokenId = creation.mint(_to);

        return tokenId;
    }

    /// @notice Mint a new authorization token for a TBA
    /// @param _to The TBA the minter of the new authorization token
    /// @return The tokenID of the new authorization token
    function mintAuthorization(address _to)
        external
        onlySignedTba(_to)
        nonReentrant
        returns (uint256)
    {
        uint256 tokenId = authorization.mintNew(_to, "");
        // With extra 10 bonus to SonarMeta
        authorization.increaseContribution(address(this), tokenId, 10, "");

        authorizationMinters[tokenId] = _to;

        emit AuthorizationMinted(tokenId, _to);

        return tokenId;
    }

    /// @notice Authorize from a TBA to another TBA (increase 1 contribution)
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _authorizationId The tokenID of the given authorization token
    /// @return The total stakeholder amount of the given authorization token
    function authorize(
        address _from,
        address _to,
        uint256 _authorizationId
    )
        external
        onlySignedTba(_from)
        onlySignedTba(_to)
        nonReentrant
        returns (uint256)
    {
        Tba storage tba = Tbas[_from];

        require(
            authorizationMinters[_authorizationId] == _from,
            "Authorization token must be published by its minter."
        );
        require(
            !tba.stakeholders[_to],
            "This TBA has been already authorized."
        );

        authorization.increaseContribution(_to, _authorizationId, 1, "");

        tba.stakeholders[_to] = true;
        tba.stakeholderCount++;

        emit Authorized(_authorizationId, _from, _to);

        return tba.stakeholderCount;
    }

    /// @notice Increase contribution from a TBA to another TBA
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _authorizationId The tokenID of the given authorization token
    /// @param _amount The contribution value that the minter wants to give
    /// @return The total contribution amount of _to
    function increaseContribution(
        address _from,
        address _to,
        uint256 _authorizationId,
        uint256 _amount
    )
        external
        onlySignedTba(_from)
        onlySignedTba(_to)
        nonReentrant
        returns (uint256)
    {
        require(
            authorizationMinters[_authorizationId] == _from,
            "Authorization token must be increased by its minter."
        );
        require(
            Tbas[_from].stakeholders[_to],
            "This TBA has not been authorized yet."
        );

        authorization.increaseContribution(_to, _authorizationId, _amount, "");

        emit ContributionIncreased(_authorizationId, _amount, _from, _to);

        return authorization.balanceOf(_to, _authorizationId);
    }

    /// @notice Deploy a new IP DAO
    function deployIpDao() external nonReentrant returns (address) {
        IpDao ipDao = new IpDao(msg.sender, creationImpAddr);
        address ipDaoAddr = address(ipDao);

        ipDaos[ipDaoAddr] = true;

        emit IpDaoDeployed(ipDaoAddr);

        return ipDaoAddr;
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Check if a TBA is signed
    function isTbaSigned(address _tbaAddr) external view returns (bool) {
        return Tbas[_tbaAddr].isSigned;
    }

    /// @notice Check if a TBA is another TBA's stakeholder
    function isStakeholder(address _stakeholderAddr, address _tbaAddr)
        external
        view
        onlySignedTba(_stakeholderAddr)
        onlySignedTba(_tbaAddr)
        returns (bool)
    {
        return Tbas[_tbaAddr].stakeholders[_stakeholderAddr];
    }

    /// @notice Get the total amount of stakeholders of a TBA
    function getStakeholderCount(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return Tbas[_tbaAddr].stakeholderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return Tbas[_tbaAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return ipDaos[_ipDaoAddr];
    }
}
