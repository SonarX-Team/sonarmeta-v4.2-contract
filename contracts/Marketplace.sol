// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SonarMeta.sol";
import "./Authorization.sol";
import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta marketplace contract for `authorization tokens`
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Marketplace is Ownable, ReentrancyGuard {
    struct Listing {
        uint256 amount;
        uint256 basePrice; // In Wei
    }

    // Track all listings, tokenID => (seller => Listing)
    mapping(uint256 => mapping(address => Listing)) private s_listings;
    // Pull over push pattern, seller => proceeds
    mapping(address => uint256) private s_proceeds;

    Authorization private s_authorization;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emitted when authorization tokens are listed or updated
    event AuthorizationListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 basePrice
    );

    /// @notice Emitted when a listing is canceled
    event ListingCanceled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emitted when authorization tokens are bought
    event AuthorizationBought(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );

    ///////////////////////   Errors   ///////////////////////

    error SellerIsNotDerivative(uint256 tokenId, address derivative);
    error PriceNotMet(uint256 tokenId, uint256 price);
    error InsufficientTokenAmount();
    error NotApprovedForMarketplace();
    error PriceMustBeAboveZero();
    error NoProceeds();

    ///////////////////   Main Functions   ///////////////////

    constructor(address _authorizationImpAddr) Ownable(msg.sender) {
        initializeReentrancyGuard();

        s_authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice Method for listing authorization token
    /// @notice Anyone can buy but the seller needs to be a derivative
    /// @param _tokenId TokenID of the authorization token
    /// @param _amount Amount of the authorization token
    /// @param _basePrice Base price for each authorization token
    /// @param _sonarmetaImpAddr Address of the SonarMeta main contract
    function listAuthorization(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _basePrice,
        address _sonarmetaImpAddr
    ) external {
        if (!s_authorization.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForMarketplace();

        if (_basePrice <= 0) revert PriceMustBeAboveZero();

        SonarMeta sonarmeta = SonarMeta(_sonarmetaImpAddr);
        if (!sonarmeta.isDerivativeByTokenId(_tokenId, msg.sender))
            revert SellerIsNotDerivative(_tokenId, msg.sender);

        uint256 value = s_authorization.balanceOf(msg.sender, _tokenId);
        if (value < _amount) revert InsufficientTokenAmount();

        s_listings[_tokenId][msg.sender] = Listing(_amount, _basePrice);

        emit AuthorizationListed(_tokenId, msg.sender, _amount, _basePrice);
    }

    /// @notice Method for cancelling listing
    /// @param _tokenId Token TokenID of the authorization token
    function cancelListing(uint256 _tokenId) external {
        delete s_listings[_tokenId][msg.sender];

        emit ListingCanceled(msg.sender, _tokenId);
    }

    /// @notice Method for buying listing for a node
    /// @notice Anyone can buy but the seller needs to be a derivative
    /// @notice The owner could unapprove the marketplace,
    /// which would cause this function to fail
    /// Ideally you'd also have a `createOffer` functionality.
    /// @param _tokenId TokenID of the authorization token
    /// @param _seller The seller of the authorization token
    /// @param _amount Amount that the buyer wants
    function buyAuthorization(
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) external payable nonReentrant {
        Listing storage listedAuthorization = s_listings[_tokenId][_seller];
        uint256 price = listedAuthorization.basePrice * _amount;

        if (_amount > listedAuthorization.amount)
            revert InsufficientTokenAmount();
        if (msg.value < price) revert PriceNotMet(_tokenId, price);

        s_proceeds[_seller] += msg.value;
        listedAuthorization.amount -= _amount;

        if (listedAuthorization.amount == 0) {
            delete s_listings[_tokenId][_seller];

            emit ListingCanceled(_seller, _tokenId);
        }

        s_authorization.safeTransferFrom(
            _seller,
            msg.sender,
            _tokenId,
            (_amount * 19) / 20, // 95% for the buyer
            ""
        );
        s_authorization.safeTransferFrom(
            _seller,
            address(this),
            _tokenId,
            (_amount * 1) / 20, // 5% for the SonarMeta protocol
            ""
        );

        emit AuthorizationBought(_tokenId, msg.sender, _amount, price);
    }

    /// @notice Method for withdrawing proceeds from sales
    function withdrawProceeds() external nonReentrant {
        uint256 proceed = s_proceeds[msg.sender];

        if (proceed <= 0) revert NoProceeds();

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceed}("");

        require(success, "Transfer failed");
    }

    //////////////////   Getter Functions   //////////////////

    /// @notice Get a listing by tokenID and its seller
    function getListing(
        uint256 _tokenId,
        address _seller
    ) external view returns (Listing memory) {
        return s_listings[_tokenId][_seller];
    }

    /// @notice Get proceeds of a seller
    function getProceeds(address _seller) external view returns (uint256) {
        return s_proceeds[_seller];
    }
}
