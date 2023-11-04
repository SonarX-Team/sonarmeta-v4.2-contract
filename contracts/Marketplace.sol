// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storage.sol";
import "./Authorization.sol";
import "./utils/ReentrancyGuard.sol";

error PriceNotMet(uint256 tokenId, uint256 price);
error ItemNotForSale(uint256 tokenId);
error NotListed(uint256 tokenId);
error AlreadyListed(uint256 tokenId);
error IsNotOwner();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error NoProceeds();

/// @title SonarMeta marketplace contract for authorization tokens
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Marketplace is Ownable, Storage, ReentrancyGuard {
    /// @notice Listing information struct
    struct Listing {
        uint256 price;
        address seller;
    }

    // Track all listings, tokenID => List info
    mapping(uint256 => Listing) private listings;
    // Pull over push patter, account => proceeds
    mapping(address => uint256) private proceeds;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a item is listed or updated
    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @notice Emitted when a item is canceled
    event ItemCanceled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emitted when a item is bought
    event ItemBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    //////////////////////////////////////////////////////////
    /////////////////////   Modifiers   //////////////////////
    //////////////////////////////////////////////////////////

    modifier notListed(uint256 tokenId) {
        Listing memory listing = listings[tokenId];
        if (listing.price > 0) revert AlreadyListed(tokenId);
        _;
    }

    modifier isListed(uint256 tokenId) {
        Listing memory listing = listings[tokenId];
        if (listing.price <= 0) revert NotListed(tokenId);
        _;
    }

    modifier isOwner(uint256 tokenId, address spender) {
        address owner = authorization.ownerOf(tokenId);
        if (spender != owner) revert NotOwner();
        _;
    }

    modifier isNotOwner(uint256 tokenId, address spender) {
        address owner = authorization.ownerOf(tokenId);
        if (spender == owner) revert IsNotOwner();
        _;
    }

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(address _authorizationImpAddr) Ownable(msg.sender) {
        initializeReentrancyGuard();
        authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice Method for listing authorization token
    /// @param tokenId TokenID of authorization
    /// @param price sale price for each item
    function listItem(uint256 tokenId, uint256 price)
        external
        notListed(tokenId)
        isOwner(tokenId, msg.sender)
    {
        if (price <= 0) revert PriceMustBeAboveZero();

        if (authorization.getApproved(tokenId) != address(this))
            revert NotApprovedForMarketplace();

        listings[tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, tokenId, price);
    }

    /// @notice Method for cancelling listing
    /// @param tokenId Token ID of NFT
    function cancelListing(uint256 tokenId)
        external
        isOwner(tokenId, msg.sender)
        isListed(tokenId)
    {
        delete listings[tokenId];
        emit ItemCanceled(msg.sender, tokenId);
    }

    /// @notice Method for buying listing
    /// @notice The owner of an NFT could unapprove the marketplace,
    /// which would cause this function to fail
    /// Ideally you'd also have a `createOffer` functionality.
    /// @param tokenId Token ID of NFT
    function buyItem(uint256 tokenId)
        external
        payable
        isListed(tokenId)
        isNotOwner(tokenId, msg.sender)
        nonReentrant
    {
        Listing memory listedItem = listings[tokenId];

        if (msg.value < listedItem.price)
            revert PriceNotMet(tokenId, listedItem.price);

        // Pull over push pattern instead of sending money straightforward
        proceeds[listedItem.seller] += msg.value;

        delete (listings[tokenId]);

        authorization.safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, tokenId, listedItem.price);
    }

    /// @notice Method for updating listing
    /// @param tokenId Token ID of NFT
    /// @param newPrice Price in Wei of the item
    function updateListing(uint256 tokenId, uint256 newPrice)
        external
        isListed(tokenId)
        isOwner(tokenId, msg.sender)
        nonReentrant
    {
        if (newPrice <= 0) revert PriceMustBeAboveZero();

        listings[tokenId].price = newPrice;

        emit ItemListed(msg.sender, tokenId, newPrice);
    }

    /// @notice Method for withdrawing proceeds from sales
    function withdrawProceeds() external nonReentrant {
        if (proceeds[msg.sender] <= 0) revert NoProceeds();

        proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{
            value: proceeds[msg.sender]
        }("");

        require(success, "Transfer failed");
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    function getListing(uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return proceeds[seller];
    }
}
