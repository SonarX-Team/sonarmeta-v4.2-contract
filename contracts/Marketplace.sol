// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Authorization.sol";
import "./utils/ReentrancyGuard.sol";

error PriceNotMet(uint256 tokenId, uint256 price);
error InsufficientTokenAmount();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error NoProceeds();

/// @title SonarMeta marketplace contract for `authorization tokens`
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Marketplace is Ownable, ReentrancyGuard {
    /// @notice Listing information struct
    struct Listing {
        uint256 amount;
        uint256 basePrice; // In Wei
    }

    // Track all listings, tokenID => (seller => Listing)
    mapping(uint256 => mapping(address => Listing)) private s_listings;
    // Pull over push pattern, seller => proceeds
    mapping(address => uint256) private s_proceeds;

    Authorization private s_authorization;

    //////////////////////////////////////////////////////////
    ///////////////////////   Events   ///////////////////////
    //////////////////////////////////////////////////////////

    /// @notice Emitted when a item is listed or updated
    event ItemListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 basePrice
    );

    /// @notice Emitted when a item is canceled
    event ItemCanceled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emitted when a item is bought
    event ItemBought(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );

    //////////////////////////////////////////////////////////
    ///////////////////   Main Functions   ///////////////////
    //////////////////////////////////////////////////////////

    constructor(address _authorizationImpAddr) Ownable(msg.sender) {
        initializeReentrancyGuard();

        s_authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice Method for listing authorization token
    /// @param _tokenId TokenID of the authorization token
    /// @param _amount Amount of the authorization token
    /// @param _basePrice Base price for each authorization token
    function listItem(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _basePrice
    ) external {
        if (!s_authorization.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForMarketplace();

        if (_basePrice <= 0) revert PriceMustBeAboveZero();

        uint256 value = s_authorization.balanceOf(msg.sender, _tokenId);
        if (value < _amount) revert InsufficientTokenAmount();

        s_listings[_tokenId][msg.sender] = Listing(_amount, _basePrice);

        emit ItemListed(_tokenId, msg.sender, _amount, _basePrice);
    }

    /// @notice Method for cancelling listing
    /// @param _tokenId Token TokenID of the authorization token
    function cancelListing(uint256 _tokenId) external {
        delete s_listings[_tokenId][msg.sender];

        emit ItemCanceled(msg.sender, _tokenId);
    }

    /// @notice Method for buying listing
    /// @notice The owner of an NFT could unapprove the marketplace,
    /// which would cause this function to fail
    /// Ideally you'd also have a `createOffer` functionality.
    /// @param _tokenId TokenID of the authorization token
    /// @param _seller The seller of the authorization token
    /// @param _amount Amount that the buyer wants
    function buyItem(
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) external payable nonReentrant {
        Listing storage listedItem = s_listings[_tokenId][_seller];
        uint256 price = listedItem.basePrice * _amount;

        if (_amount > listedItem.amount) revert InsufficientTokenAmount();
        if (msg.value < price) revert PriceNotMet(_tokenId, price);

        s_proceeds[_seller] += msg.value;
        listedItem.amount -= _amount;

        if (listedItem.amount == 0) {
            delete s_listings[_tokenId][_seller];

            emit ItemCanceled(_seller, _tokenId);
        }

        s_authorization.safeTransferFrom(
            _seller,
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit ItemBought(_tokenId, msg.sender, _amount, price);
    }

    /// @notice Method for withdrawing proceeds from sales
    function withdrawProceeds() external nonReentrant {
        uint256 proceed = s_proceeds[msg.sender];

        if (proceed <= 0) revert NoProceeds();

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceed}("");

        require(success, "Transfer failed");
    }

    //////////////////////////////////////////////////////////
    //////////////////   Getter Functions   //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Get a listing by tokenID and its seller
    function getListing(uint256 _tokenId, address _seller)
        external
        view
        returns (Listing memory)
    {
        return s_listings[_tokenId][_seller];
    }

    /// @notice Get proceeds of a seller
    function getProceeds(address _seller) external view returns (uint256) {
        return s_proceeds[_seller];
    }
}
