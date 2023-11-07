// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./Creation.sol";
import "./Authorization.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Counters.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is Ownable, Storage, ReentrancyGuard {
    /// @notice TBA information struct
    struct TBA {
        bool isSigned; // If this TBA is signed to use SonarMeta
        mapping(address => bool) stakeholders; // All Stakeholder TBAs of this TBA
        uint stakeholderCount; // The amount of stakeholder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    // Track TBA infos, TBA address => TBA info
    mapping(address => TBA) private TBAs;
    // Track minters of authorization tokens, tokenID => TBA address
    mapping(uint256 => address) private authorizationMinters;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a TBA is signed to use SonarMeta
    event TBASigned(address indexed tbaAddr);

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

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier onlySignedTBA(address _tbaAddr) {
        require(
            TBAs[_tbaAddr].isSigned,
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
    }

    /// @notice A TBA sign to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    function signToUseSonarMeta(address _tbaAddr) external nonReentrant {
        TBA storage tba = TBAs[_tbaAddr];
        tba.isSigned = true;

        emit TBASigned(_tbaAddr);
    }

    /// @notice Create a new creation/component token
    /// Currently in the demo version, every component of a co-creation MUST be a SonarMeta creation
    /// because we only use these components to calculate the proceeds of every co-creation member
    /// @param _to The account the owner of the new creation/component token
    /// @param _uri The tokenURI the metadata of the new creation/component token needs
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to, string memory _uri)
        external
        nonReentrant
        returns (uint256)
    {
        uint256 tokenId = creation.mint(_to, _uri);

        return tokenId;
    }

    /// @notice Mint a new authorization token for a TBA
    /// @param _to The TBA the minter of the new authorization token
    /// @param _uri The tokenURI the metadata of the new authorization token needs
    /// @return The tokenID of the new authorization token
    function mintAuthorization(address _to, string memory _uri)
        external
        onlySignedTBA(_to)
        nonReentrant
        returns (uint256)
    {
        uint256 tokenId = authorization.mint(_to, _uri);
        // With extra bonus to SonarMeta
        authorization.mint(address(this), _uri);

        authorizationMinters[tokenId] = _to;

        emit AuthorizationMinted(tokenId, _to);

        return tokenId;
    }

    /// @notice Authorize from a TBA to another TBA
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
        onlySignedTBA(_from)
        onlySignedTBA(_to)
        nonReentrant
        returns (uint256)
    {
        TBA storage tba = TBAs[_from];

        require(
            authorizationMinters[_authorizationId] == _from,
            "Authorization token must be published by its minter."
        );
        require(
            !tba.stakeholders[_to],
            "This TBA has been already authorized."
        );

        authorization.safeTransferFrom(_from, _to, _authorizationId);

        tba.stakeholders[_to] = true;
        tba.stakeholderCount++;

        emit Authorized(_authorizationId, _from, _to);

        return tba.stakeholderCount;
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Get the total amount of stakeholders of a TBA
    function getStakeholderCount(address _tbaAddr)
        external
        view
        onlySignedTBA(_tbaAddr)
        returns (uint256)
    {
        return TBAs[_tbaAddr].stakeholderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(address _tbaAddr)
        external
        view
        onlySignedTBA(_tbaAddr)
        returns (uint256)
    {
        return TBAs[_tbaAddr].nodeValue;
    }
}
