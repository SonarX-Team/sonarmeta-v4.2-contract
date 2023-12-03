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

    constructor(address _creationImpAddr, address _authorizationImpAddr)
        Ownable(msg.sender)
    {
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

    /// @notice A TBA sign to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function signToUse(address _tbaAddr, uint256 _tokenId)
        external
        nonReentrant
    {
        Tba storage tba = s_tbas[_tbaAddr];
        tba.isSigned = true;

        s_tbas[_tbaAddr].tokenId = _tokenId;

        emit TbaSigned(_tbaAddr);
    }

    /// @notice Mint a corresponding authorization token to activate authorization functionality
    /// @param _tbaAddr The TBA address wants to activate authorization
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function activateAuthorization(address _tbaAddr, uint256 _tokenId)
        external
        onlySignedTba(_tbaAddr)
        onlyIssuer(_tbaAddr, _tokenId)
        nonReentrant
    {
        s_authorization.claimNew(_tbaAddr, _tokenId);
    }

    /// @notice Authorize from a TBA to another TBA (increase 1 contribution)
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @return The total holder amount of the creation
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
        Tba storage tba = s_tbas[_from];

        s_authorization.increase(_to, _tokenId, 1);
        // With 10 bonus to SonarMeta
        s_authorization.increase(address(this), _tokenId, 10);

        tba.holders[_to] = true;
        tba.holderCount++;

        emit Authorized(_tokenId, _from, _to);

        return tba.holderCount;
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
        require(_amount > 0, "Contribution amount must be above 0.");

        s_authorization.increase(_to, _tokenId, _amount);
        // With 10 bonus to SonarMeta
        s_authorization.increase(address(this), _tokenId, 10);

        emit Contributed(_tokenId, _amount, _from, _to);

        return s_authorization.balanceOf(_to, _tokenId);
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

    /// @notice Check if a TBA is another TBA's holder
    function isHolder(address _holderAddr, address _tbaAddr)
        external
        view
        onlySignedTba(_holderAddr)
        onlySignedTba(_tbaAddr)
        returns (bool)
    {
        return s_tbas[_tbaAddr].holders[_holderAddr];
    }

    /// @notice Get the total amount of holders of a TBA
    function getHolderCount(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return s_tbas[_tbaAddr].holderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return s_tbas[_tbaAddr].nodeValue;
    }

    /// @notice Check if an IP DAO is tracked
    function isIpDaoTracked(address _ipDaoAddr) external view returns (bool) {
        return s_ipDaos[_ipDaoAddr];
    }
}
