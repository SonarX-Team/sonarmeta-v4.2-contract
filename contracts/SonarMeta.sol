// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./Creation.sol";
import "./Authorization.sol";
import "./tokenboundaccount/ERC6551Registry.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/ChainlinkVRF.sol";
import "./utils/Counters.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is Ownable, Storage, ReentrancyGuard {
    /// @notice TBA information struct
    struct TBA {
        bool existing; // If this TBA exists
        mapping(address => bool) stakeholders; // All Stakeholder TBAs of this TBA
        uint stakeholderCount; // The amount of stakeholder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    address private creationImpAddr; // Creation token implementation address
    address private tbaImpAddr; // TBA implementation address
    address private marketplaceImpAddr; // Marketplace implementation address

    // Track TBAs created by SonarMeta, TBA address => TBA info
    mapping(address => TBA) public TBAs;
    // Track minters of authorization tokens, tokenID => TBA address
    mapping(uint256 => address) public authorizationMinters;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a TBA is minted for a creation token
    event TBAMinted(
        address indexed tbaAddr,
        address indexed creationImpAddr,
        uint256 indexed creationId,
        uint256 chainId
    );

    /// @notice Emitted when authorization tokens are minted or increased
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

    modifier onlySonarMetaTBA(address _tbaAddr) {
        require(
            TBAs[_tbaAddr].existing,
            "Address provided must be a TBA tracked by SonarMeta."
        );
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(
        address _creationImpAddr,
        address _authorizationImpAddr,
        address _tbaImpAddr,
        address _registryAddr,
        address _marketplaceImpAddr,
        address _chainlinkVRFImpAddr
    ) Ownable(msg.sender) {
        initializeReentrancyGuard();

        governance = Governance(owner());
        creation = Creation(_creationImpAddr);
        authorization = Authorization(_authorizationImpAddr);
        registry = ERC6551Registry(_registryAddr);
        randomGenerator = ChainlinkVRF(_chainlinkVRFImpAddr);

        creationImpAddr = _creationImpAddr;
        tbaImpAddr = _tbaImpAddr;
        marketplaceImpAddr = _marketplaceImpAddr;
    }

    /// @notice Create a new TBA for an existing creation token and track it
    /// @param _creationImpAddr The implementation address of the given creation token
    /// @param _creationId The tokenID of the given creation token
    /// @param _chainId The ID of the chain provided to ERC6551 Registry
    /// @return The TBA address created for the existing creation token
    function mintTBAForCreation(
        address _creationImpAddr,
        uint256 _creationId,
        uint256 _chainId
    ) public nonReentrant returns (address) {
        address tbaAddr = registry.createAccount(
            tbaImpAddr,
            _chainId,
            _creationImpAddr,
            _creationId,
            generateRandom(10000),
            ""
        );

        TBA storage tba = TBAs[tbaAddr];
        tba.existing = true;

        emit TBAMinted(tbaAddr, _creationImpAddr, _creationId, _chainId);

        return tbaAddr;
    }

    /// @notice Create a new creation token with TBA
    /// @param _to The account the owner of the new creation token
    /// @param _uri The tokenURI the metadata of the token needs
    /// @param _chainId The ID of the chain provided to ERC6551 Registry
    /// @return The TBA address created for the new creation token
    /// @return The tokenID of the new creation token
    function mintCreationWithTBA(
        address _to,
        string memory _uri,
        uint256 _chainId
    ) external nonReentrant returns (address, uint256) {
        uint256 tokenId = creation.mint(_to, _uri);

        address tbaAddr = mintTBAForCreation(
            creationImpAddr,
            tokenId,
            _chainId
        );

        return (tbaAddr, tokenId);
    }

    /// @notice Mint a new authorization token for a TBA
    /// @param _to The TBA the minter of the new authorization token
    /// @param _uri The tokenURI the metadata of the token needs
    /// @return The tokenID of the new authorization token
    function mintAuthorization(address _to, string memory _uri)
        external
        onlySonarMetaTBA(_to)
        nonReentrant
        returns (uint256)
    {
        uint256 tokenId = authorization.mint(_to, _uri);

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
    ) external nonReentrant returns (uint256) {
        TBA storage tba = TBAs[_from];

        require(
            authorizationMinters[_authorizationId] == _from,
            "Authorization token must be published by its minter."
        );
        require(
            !tba.stakeholders[_to],
            "This TBA has been already authorized."
        );

        authorization.approve(marketplaceImpAddr, _authorizationId);
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
        onlySonarMetaTBA(_tbaAddr)
        returns (uint256)
    {
        return TBAs[_tbaAddr].stakeholderCount;
    }

    /// @notice Get the nodeValue of a TBA
    function getNodeValue(address _tbaAddr)
        external
        view
        onlySonarMetaTBA(_tbaAddr)
        returns (uint256)
    {
        return TBAs[_tbaAddr].nodeValue;
    }

    /// @notice Generate random value by Chainlink VRF
    function generateRandom(uint256 maxNum) internal returns (uint256) {
        uint256 requestId = randomGenerator.requestRandomWords();
        return (randomGenerator.getRandomNum(requestId) % maxNum);
    }
}
