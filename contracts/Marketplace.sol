// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./Authorization.sol";
import "./utils/ReentrancyGuard.sol";

error PriceNotMet(uint256 tokenId, uint256 price);
error ItemNotForSale(uint256 tokenId);
error NotListed(uint256 tokenId);
error AlreadyListed(uint256 tokenId);
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error NoProceeds();

/// @title SonarMeta marketplace contract for `authorization tokens`
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Marketplace is Ownable, Storage, ReentrancyGuard {
    /// @notice Listing information struct
    struct Listing {
        uint256 amount;
        uint256 basePrice;
        address seller;
    }

    // Track all listings, authorization tokenID => List info
    mapping(uint256 => Listing) private listings;
    // Pull over push pattern, seller address => proceeds
    mapping(address => uint256) private proceeds;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a item is listed or updated
    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 basePrice
    );

    /// @notice Emitted when a item is canceled
    event ItemCanceled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emitted when a item is bought
    event ItemBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier notListed(uint256 _tokenId) {
        Listing memory listing = listings[_tokenId];
        if (listing.basePrice > 0) revert AlreadyListed(_tokenId);
        _;
    }

    modifier isListed(uint256 _tokenId) {
        Listing memory listing = listings[_tokenId];
        if (listing.basePrice <= 0) revert NotListed(_tokenId);
        _;
    }

    modifier isOwner(uint256 _tokenId, address _spender) {
        uint256 value = authorization.balanceOf(_spender, _tokenId);
        if (value <= 0) revert NotOwner();
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(address _authorizationImpAddr) Ownable(msg.sender) {
        initializeReentrancyGuard();

        authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice Method for listing an authorization token
    /// @param _tokenId TokenID of the authorization token
    /// @param _basePrice base price for each authorization token
    /// @param _amount Amount of the authorization token
    function listItem(
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _amount
    ) external notListed(_tokenId) isOwner(_tokenId, msg.sender) {
        if (_basePrice <= 0) revert PriceMustBeAboveZero();

        if (authorization.isApprovedForAll(address(this), msg.sender))
            revert NotApprovedForMarketplace();

        listings[_tokenId] = Listing(_amount, _basePrice, msg.sender);

        emit ItemListed(msg.sender, _tokenId, _amount, _basePrice);
    }

    /// @notice Method for cancelling listing
    /// @param _tokenId Token TokenID of the authorization token
    function cancelListing(uint256 _tokenId)
        external
        isOwner(_tokenId, msg.sender)
        isListed(_tokenId)
    {
        delete listings[_tokenId];

        emit ItemCanceled(msg.sender, _tokenId);
    }

    /// @notice Method for buying listing
    /// @notice The owner of an NFT could unapprove the marketplace,
    /// which would cause this function to fail
    /// Ideally you'd also have a `createOffer` functionality.
    /// @param _tokenId TokenID of the authorization token
    /// @param _amount Amount that the buyer wants
    function buyItem(uint256 _tokenId, uint256 _amount)
        external
        payable
        isListed(_tokenId)
        nonReentrant
    {
        Listing memory listedItem = listings[_tokenId];
        uint256 price = listedItem.basePrice * _amount;

        if (msg.value < price) revert PriceNotMet(_tokenId, price);

        // Pull over push pattern instead of sending money straightforward
        proceeds[listedItem.seller] += msg.value;

        delete listings[_tokenId];

        authorization.safeTransferFrom(
            listedItem.seller,
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit ItemBought(msg.sender, _tokenId, _amount, price);
    }

    /// @notice Method for updating listing
    /// @param _tokenId TokenID of the authorization token
    /// @param _newPrice Price in Wei of the authorization token
    function updateListing(uint256 _tokenId, uint256 _newPrice)
        external
        isListed(_tokenId)
        isOwner(_tokenId, msg.sender)
        nonReentrant
    {
        if (_newPrice <= 0) revert PriceMustBeAboveZero();

        listings[_tokenId].basePrice = _newPrice;

        emit ItemListed(
            msg.sender,
            _tokenId,
            listings[_tokenId].amount,
            _newPrice
        );
    }

    /// @notice Method for withdrawing proceeds from sales
    function withdrawProceeds() external nonReentrant {
        uint256 proceed = proceeds[msg.sender];

        if (proceed <= 0) revert NoProceeds();

        proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceed}("");

        require(success, "Transfer failed");
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Get a listing by the authorization tokenID
    function getListing(uint256 _tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[_tokenId];
    }

    /// @notice Get proceeds of a seller
    function getProceeds(address _seller) external view returns (uint256) {
        return proceeds[_seller];
    }
}
