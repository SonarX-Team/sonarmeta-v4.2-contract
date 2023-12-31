// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SonarMeta.sol";
import "./Business.sol";
import "./Authorization.sol";

import "./utils/ReentrancyGuard.sol";

/// @title SonarMeta marketplace contract for `authorization tokens`
/// @author SonarX (Hangzhou) Technology Co., Ltd.
contract Marketplace is ReentrancyGuard {
    struct Listing {
        uint256 amount;
        uint256 basePrice; // In Wei
    }

    uint256 private s_sonarmetaFee;

    // Track all listings, tokenID => (seller => Listing)
    mapping(uint256 => mapping(address => Listing)) private s_listings;
    // Pull over push pattern, seller/business => proceeds
    mapping(address => uint256) private s_proceeds;

    SonarMeta private s_sonarmeta;
    Business private s_business;
    Authorization private s_authorization;

    ///////////////////////   Events   ///////////////////////

    /// @notice Emit when authorization tokens are listed or updated
    event Listed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 basePrice
    );

    /// @notice Emit when a listing is canceled
    event ListingCanceled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emit when authorization tokens are bought
    event ListingBought(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );

    ///////////////////////   Errors   ///////////////////////

    error SellerNeitherOriginalNorDerivative(
        uint256 tokenId,
        address derivative
    );
    error PriceNotMet(uint256 tokenId, uint256 bid, uint256 price);
    error InsufficientTokenAmount();
    error NotApprovedForMarketplace();
    error PriceMustBeAboveZero();
    error NoProceeds(address seller);
    error OnlySonarMetaOwnerAllowed();

    /////////////////////   Modifiers   //////////////////////

    modifier onlySonarMetaOwner(address _sonarmetaOwner) {
        if (s_sonarmeta.owner() != _sonarmetaOwner)
            revert OnlySonarMetaOwnerAllowed();
        _;
    }

    ///////////////////   Main Functions   ///////////////////

    constructor(
        address _sonarmetaImpAddr,
        address _businessImpAddr,
        address _authorizationImpAddr
    ) {
        initializeReentrancyGuard();

        s_sonarmeta = SonarMeta(_sonarmetaImpAddr);
        s_business = Business(_businessImpAddr);
        s_authorization = Authorization(_authorizationImpAddr);
    }

    /// @notice Method for listing authorization token
    /// @notice Anyone can buy but the seller needs to be a derivative
    /// @param _tokenId TokenID of the authorization token
    /// @param _amount Amount of the authorization token
    /// @param _basePrice Base price for each authorization token
    function listForSale(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _basePrice
    ) external {
        if (!s_authorization.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForMarketplace();

        if (_basePrice <= 0) revert PriceMustBeAboveZero();

        if (
            !s_sonarmeta.isOriginal(msg.sender, _tokenId) &&
            !s_sonarmeta.isDerivativeByTokenId(_tokenId, msg.sender)
        ) revert SellerNeitherOriginalNorDerivative(_tokenId, msg.sender);

        uint256 value = s_authorization.balanceOf(msg.sender, _tokenId);
        if (value < _amount) revert InsufficientTokenAmount();

        s_listings[_tokenId][msg.sender] = Listing(_amount, _basePrice);

        emit Listed(_tokenId, msg.sender, _amount, _basePrice);
    }

    /// @notice Method for cancelling listing
    /// @param _tokenId Token TokenID of the authorization token
    function cancelListing(uint256 _tokenId) external {
        delete s_listings[_tokenId][msg.sender];

        emit ListingCanceled(msg.sender, _tokenId);
    }

    /// @notice Method for buying listing by a node
    /// @notice Anyone can buy BUT the seller needs to be the original or a derivative
    /// @notice The owner could unapprove the marketplace, which would cause this function to fail
    /// Ideally we'd also have a `createOffer` functionality.
    /// @param _tokenId TokenID of the authorization token
    /// @param _seller The seller of the authorization token
    /// @param _amount Amount that the buyer wants
    /// @param _businessAddrs The addresses of the related businesses
    function buyListing(
        uint256 _tokenId,
        address _seller,
        uint256 _amount,
        address[] memory _businessAddrs
    ) external payable nonReentrant {
        Listing storage listing = s_listings[_tokenId][_seller];

        uint256 price = listing.basePrice * _amount;
        uint256 sonarmetaFee = price * s_sonarmeta.getSonarMetaRoi();
        uint256 totalFee = sonarmetaFee;

        if (_amount > listing.amount) revert InsufficientTokenAmount();
        if (msg.value < price) revert PriceNotMet(_tokenId, msg.value, price);

        uint256 businessTotalRate;
        for (uint256 i = 0; i < _businessAddrs.length; i++) {
            uint256 rateOfReturn = s_business.getBusinessRoi(_businessAddrs[i]);
            businessTotalRate += rateOfReturn;

            s_proceeds[_businessAddrs[i]] += price * rateOfReturn;
        }
        totalFee = sonarmetaFee + (price * businessTotalRate);

        s_proceeds[_seller] += price - totalFee;
        s_sonarmetaFee += sonarmetaFee;

        listing.amount -= _amount;
        if (listing.amount == 0) {
            delete s_listings[_tokenId][_seller];

            emit ListingCanceled(_seller, _tokenId);
        }

        s_authorization.safeTransferFrom(
            _seller,
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit ListingBought(_tokenId, msg.sender, _amount, price);
    }

    /// @notice Method for withdrawing proceeds by sellers/businesses
    function withdrawProceeds() external nonReentrant {
        uint256 proceeds = s_proceeds[msg.sender];

        if (proceeds <= 0) revert NoProceeds(msg.sender);

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Native token transfer failed");
    }

    /// @notice Method for withdrawing proceeds by SonarMeta
    function withdrawBySonarMeta()
        external
        onlySonarMetaOwner(msg.sender)
        nonReentrant
    {
        require(s_sonarmetaFee > 0, "No native token to withdraw");

        (bool success, ) = payable(s_sonarmeta.owner()).call{
            value: s_sonarmetaFee
        }("");
        require(success, "Native token transfer failed");
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
    function getSellerProceeds(
        address _seller
    ) external view returns (uint256) {
        return s_proceeds[_seller];
    }

    /// @notice Get proceeds of SonarMeta
    function getSonarMetaProceeds() external view returns (uint256) {
        return s_sonarmetaFee;
    }
}
