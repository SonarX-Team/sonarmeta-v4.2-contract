// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CreationCollection.sol";
import "./AuthorizationCollection.sol";
import "./AuthorizationToken.sol";
import "./IpDao.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Governance.sol";

/// @title SonarMeta main contract
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract SonarMeta is ERC1155Holder, Ownable, ReentrancyGuard {
    /// @notice Token-bound account information struct
    struct Tba {
        bool isSigned; // If this TBA is signed to use SonarMeta
        bytes32 tokenId; // The tokenID of the corresponding creation
        mapping(address => bool) holders; // All holder TBAs of this TBA
        uint256 holderCount; // The amount of holder TBAs of this TBA
        uint256 nodeValue; // The value of this TBA
    }

    // Track TBA infos, TBA address => TBA info
    mapping(address => Tba) private tbas;
    // Track all IP DAOs deployed by SonarMeta
    mapping(address => bool) private ipDaos;

    Governance private governance;
    CreationCollection private creation;
    AuthorizationCollection private authorization;
    address payable private creationImpAddr;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a TBA is signed to use SonarMeta
    event TbaSigned(address indexed tbaAddr);

    /// @notice Emitted when authorized
    event Authorized(
        bytes32 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /// @notice Emitted when contribution increased
    event Contributed(
        bytes32 indexed tokenId,
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

    modifier onlyIssuer(address _tbaAddr, bytes32 _tokenId) {
        require(
            tbas[_tbaAddr].tokenId == _tokenId,
            "Authorization token must be issued by its corresponding creation's TBA."
        );
        _;
    }

    modifier onlyHolder(address _issuer, address _holder) {
        require(
            tbas[_issuer].holders[_holder],
            "This TBA has not been authorized (a holder) yet."
        );
        _;
    }

    modifier onlyNotHolder(address _issuer, address _holder) {
        require(
            !tbas[_issuer].holders[_holder],
            "This TBA has been already (a holder) authorized."
        );
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(
        address payable _creationImpAddr,
        address payable _authorizationImpAddr
    ) Ownable(msg.sender) {
        initializeReentrancyGuard();

        governance = Governance(owner());
        creation = CreationCollection(_creationImpAddr);
        authorization = AuthorizationCollection(_authorizationImpAddr);

        creationImpAddr = _creationImpAddr;
    }

    /// @notice Mint a new creation/component token
    /// @param _to The account the owner of the new creation/component token
    /// @return The tokenID of the new creation/component token
    function mintCreation(address _to) external nonReentrant returns (bytes32) {
        // Since tokenId type is number in creation collection
        // Use something like a increasing counter to mint
        uint256 currentCount = creation.totalSupply() + 1;
        bytes32 tokenId = bytes32(abi.encode(currentCount));

        creation.mint(_to, tokenId, false, "");

        return tokenId;
    }

    /// @notice A TBA sign to use SonarMeta
    /// @param _tbaAddr The TBA address wants to sign
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function signToUse(address _tbaAddr, bytes32 _tokenId)
        external
        nonReentrant
    {
        Tba storage tba = tbas[_tbaAddr];
        tba.isSigned = true;

        tbas[_tbaAddr].tokenId = _tokenId;

        emit TbaSigned(_tbaAddr);
    }

    /// @notice Mint a corresponding authorization token to activate authorization functionality
    /// @param _tbaAddr The TBA address wants to activate authorization
    /// @param _tokenId The creation tokenID corresponding to this TBA
    function activateAuthorization(address _tbaAddr, bytes32 _tokenId)
        external
        onlySignedTba(_tbaAddr)
        onlyIssuer(_tbaAddr, _tokenId)
        nonReentrant
    {
        authorization.claimNew(_tbaAddr, _tokenId);
    }

    /// @notice Authorize from a TBA to another TBA (increase 1 contribution)
    /// @param _from The TBA which will publish the authorization token
    /// @param _to The TBA which will receive the authorization token
    /// @param _tokenId The tokenID of the creation token
    /// @return The total holder amount of the creation
    function authorize(
        address _from,
        address _to,
        bytes32 _tokenId
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

        authorization.increase(_to, _tokenId, 1);
        // With 10 bonus to SonarMeta
        // This is our TODO business model that any `authorize` can be our profitable point
        authorization.increase(address(this), _tokenId, 10);

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
        bytes32 _tokenId,
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

        authorization.increase(_to, _tokenId, _amount);
        // With 10 bonus to SonarMeta
        // This is our TODO business model that any `contribute` can be our profitable point
        authorization.increase(address(this), _tokenId, 10);

        emit Contributed(_tokenId, _amount, _from, _to);

        // Decode authorizationTokenId to get the tokenId, which is an address
        // And get the implementation of the authorization token
        AuthorizationToken authorizationToken = AuthorizationToken(
            abi.decode(abi.encodePacked(_tokenId), (address))
        );

        // LSP-7 balanceOf to figure out the value that _to holds
        return authorizationToken.balanceOf(_to);
    }

    /// @notice Deploy a new IP DAO
    function deployIpDao() external nonReentrant returns (address) {
        IpDao ipDao = new IpDao(msg.sender, creationImpAddr);
        address ipDaoAddr = address(ipDao);

        ipDaos[ipDaoAddr] = true;

        emit IpDaoDeployed(ipDaoAddr, msg.sender);

        return ipDaoAddr;
    }

    /// @notice Method for withdrawing authorization tokens to SonarMeta's team
    /// This is our TODO business model that we can withdraw authorization tokens from here
    /// And list them on Marketplace to be one of a seller in competition
    function withdraw() external onlyOwner nonReentrant {
        bytes32[] memory authorizationIds = authorization.tokenIdsOf(
            address(this)
        );
        uint256[] memory amounts = new uint256[](authorizationIds.length);
        address[] memory froms = new address[](authorizationIds.length);
        address[] memory tos = new address[](authorizationIds.length);
        bool[] memory forces = new bool[](authorizationIds.length);
        bytes[] memory datas = new bytes[](authorizationIds.length);

        for (uint256 i = 0; i < authorizationIds.length; i++) {
            // Decode authorizationTokenId to get the tokenId, which is an address
            // And get the implementation of the authorization token
            AuthorizationToken authorizationToken = AuthorizationToken(
                abi.decode(abi.encodePacked(authorizationIds[i]), (address))
            );

            // LSP-7 transfer
            authorizationToken.transfer(
                address(this),
                msg.sender,
                authorizationToken.balanceOf(address(this)),
                false,
                ""
            );

            // LSP-7 balanceOf to figure out value that SonarMeta contract holds
            amounts[i] = authorizationToken.balanceOf(address(this));
            froms[i] = address(this);
            tos[i] = msg.sender;
            forces[i] = false;
            datas[i] = "";
        }

        // LSP-8 transfer batch
        authorization.transferBatch(
            froms,
            tos,
            authorizationIds,
            forces,
            datas
        );
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Check if a TBA is signed
    function isTbaSigned(address _tbaAddr) external view returns (bool) {
        return tbas[_tbaAddr].isSigned;
    }

    /// @notice Check if a TBA is another TBA's holder
    function isHolder(address _holderAddr, address _tbaAddr)
        external
        view
        onlySignedTba(_holderAddr)
        onlySignedTba(_tbaAddr)
        returns (bool)
    {
        return tbas[_tbaAddr].holders[_holderAddr];
    }

    /// @notice Get the total amount of holders of a TBA
    function getHolderCount(address _tbaAddr)
        external
        view
        onlySignedTba(_tbaAddr)
        returns (uint256)
    {
        return tbas[_tbaAddr].holderCount;
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
