// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

interface IPixellyAddressRegistry {
    function pixellyNFT() external view returns (address);

    function bundleMarketplace() external view returns (address);

    function auction() external view returns (address);

    function factory() external view returns (address);

    function privateFactory() external view returns (address);

    function artFactory() external view returns (address);

    function privateArtFactory() external view returns (address);

    function tokenRegistry() external view returns (address);

    function priceFeed() external view returns (address);

    function royaltyRegistry() external view returns (address);
}

interface IPixellyAuction {
    function auctions(address, uint256)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            bool
        );
}

interface IPixellyBundleMarketplace {
    function validateItemSold(
        address,
        uint256,
        uint256
    ) external;
}

interface IPixellyNFTFactory {
    function exists(address) external view returns (bool);
}

interface IPixellyTokenRegistry {
    function enabled(address) external view returns (bool);
}

interface IPixellyPriceFeed {
    function wETH() external view returns (address);

    function getPrice(address) external view returns (int256, uint8);
}

interface IPixellyRoyaltyRegistry {
    function royaltyInfo(
        address _collection,
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);
}

contract PixellyMarketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Events for the contract
    event ItemListed(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem,
        uint256 startingTime
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        int256 unitPrice,
        uint256 pricePerItem
    );
    event ItemUpdated(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 newPrice
    );
    event ItemCanceled(
        address indexed owner,
        address indexed nft,
        uint256 tokenId
    );
    event OfferCreated(
        address indexed creator,
        address indexed nft,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem,
        uint256 deadline
    );
    event CounterOfferCreated(
        address indexed creator,
        address indexed addressee,
        address indexed nft,
        uint256 tokenId,
        Offer counteroffer
    );
    event OfferCanceled(
        address indexed creator,
        address indexed nft,
        uint256 tokenId
    );
    event CounterOfferCanceled(
        address indexed creator,
        address indexed addressee,
        address indexed nft,
        uint256 tokenId
    );
    event OfferRefused(
        address indexed creator,
        address indexed nft,
        uint256 tokenId
    );
    event CounterOfferRefused(
        address indexed creator,
        address indexed addressee,
        address indexed nft,
        uint256 tokenId
    );
    event UpdatePlatformFee(uint16 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    /// @notice Structure for listed items
    struct Listing {
        uint256 quantity;
        address payToken;
        uint256 pricePerItem;
        uint256 startingTime;
    }

    /// @notice Structure for offer
    struct Offer {
        IERC20Upgradeable payToken;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 deadline;
    }

    struct CollectionRoyalty {
        uint16 royalty;
        address creator;
        address feeRecipient;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice NftAddress -> Token ID -> Minter
    mapping(address => mapping(uint256 => address)) public minters;

    /// @notice NftAddress -> Token ID -> Royalty
    mapping(address => mapping(uint256 => uint16)) public royalties;

    /// @notice NftAddress -> Token ID -> Owner -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    /// @notice NftAddress -> Token ID -> Offerer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    /// @notice NftAddress -> Token ID -> Addressee of the counter offer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public counterOffers;

    /// @notice NFTAddress -> TokenID -> Owner
    mapping(address => mapping(uint256 => address)) public ownerOfERC1155;

    /// @notice Platform fee
    uint16 public platformFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    /// @notice NftAddress -> Royalty
    mapping(address => CollectionRoyalty) public collectionRoyalties;

    /// @notice Address registry
    IPixellyAddressRegistry public addressRegistry;

    modifier onlyMarketplace() {
        require(
            address(addressRegistry.bundleMarketplace()) == _msgSender(),
            "sender must be bundle marketplace"
        );
        _;
    }

    modifier isListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = listings[_nftAddress][_tokenId][_owner];
        require(listing.quantity > 0, "not listed item");
        _;
    }

    modifier notListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = listings[_nftAddress][_tokenId][_owner];
        require(listing.quantity == 0, "already listed");
        _;
    }

    modifier validListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        _validOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

        require(_getNow() >= listedItem.startingTime, "item not buyable");
        _;
    }

    modifier offerExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        require(
            offer.quantity > 0 && offer.deadline > _getNow(),
            "offer not exists or expired"
        );
        _;
    }

    modifier counterOfferExists(
        address _nftAddress,
        uint256 _tokenId,
        address _addressee
    ) {
        Offer memory counterOffer = counterOffers[_nftAddress][_tokenId][
            _addressee
        ];
        require(
            counterOffer.quantity > 0 && counterOffer.deadline > _getNow(),
            "counter offer not exists or expired"
        );
        _;
    }

    modifier offerNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];
        require(
            offer.quantity == 0 || offer.deadline <= _getNow(),
            "offer already created"
        );
        _;
    }

    modifier counterOfferNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _addressee
    ) {
        Offer memory counterOffer = counterOffers[_nftAddress][_tokenId][
            _addressee
        ];
        require(
            counterOffer.quantity == 0 || counterOffer.deadline <= _getNow(),
            "counter offer already created"
        );
        _;
    }

    /// @notice Contract initializer
    function initialize(address payable _feeRecipient, uint16 _platformFee)
        public
        initializer
    {
        platformFee = _platformFee;
        feeReceipient = _feeRecipient;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Method for listing NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _payToken Paying token
    /// @param _pricePerItem sale price for each iteam
    /// @param _startingTime scheduling for a future sale
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _pricePerItem,
        uint256 _startingTime
    ) external notListed(_nftAddress, _tokenId, _msgSender()) {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "not owning item");
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "item not approved"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= _quantity,
                "must hold enough nfts"
            );
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "item not approved"
            );
        } else {
            revert("invalid nft address");
        }

        _validPayToken(_payToken);

        listings[_nftAddress][_tokenId][_msgSender()] = Listing(
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime
        );
        emit ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _payToken,
            _pricePerItem,
            _startingTime
        );
    }

    /// @notice Method for canceling listed NFT
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _msgSender())
    {
        _cancelListing(_nftAddress, _tokenId, _msgSender());
    }

    /// @notice Method for updating listed NFT
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _payToken payment token
    /// @param _newPrice New sale price for each iteam
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice
    ) external nonReentrant isListed(_nftAddress, _tokenId, _msgSender()) {
        Listing storage listedItem = listings[_nftAddress][_tokenId][
            _msgSender()
        ];

        _validOwner(_nftAddress, _tokenId, _msgSender(), listedItem.quantity);

        _validPayToken(_payToken);

        listedItem.payToken = _payToken;
        listedItem.pricePerItem = _newPrice;
        emit ItemUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _newPrice
        );
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner
    )
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _owner)
        validListing(_nftAddress, _tokenId, _owner)
    {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];
        require(listedItem.payToken == _payToken, "invalid pay token");

        _buyItem(_nftAddress, _tokenId, _payToken, _owner);
    }

    function _buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        uint256 price = listedItem.pricePerItem.mul(listedItem.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e3);

        IERC20Upgradeable(_payToken).safeTransferFrom(
            _msgSender(),
            feeReceipient,
            feeAmount
        );

        IPixellyRoyaltyRegistry royaltyRegistry = IPixellyRoyaltyRegistry(
            addressRegistry.royaltyRegistry()
        );

        address minter;
        uint256 royaltyAmount;

        (minter, royaltyAmount) = royaltyRegistry.royaltyInfo(
            _nftAddress,
            _tokenId,
            price.sub(feeAmount)
        );
        if (minter != address(0) && royaltyAmount != 0) {
            IERC20Upgradeable(_payToken).safeTransferFrom(
                _msgSender(),
                minter,
                royaltyAmount
            );

            feeAmount = feeAmount.add(royaltyAmount);
        }

        IERC20Upgradeable(_payToken).safeTransferFrom(
            _msgSender(),
            _owner,
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId,
                listedItem.quantity,
                bytes("")
            );
        }
        IPixellyBundleMarketplace(addressRegistry.bundleMarketplace())
            .validateItemSold(_nftAddress, _tokenId, listedItem.quantity);

        emit ItemSold(
            _owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            listedItem.quantity,
            _payToken,
            getPrice(_payToken),
            price.div(listedItem.quantity)
        );
        delete (listings[_nftAddress][_tokenId][_owner]);
    }

    /// @notice Method for buying listed NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function buyItemWithQuantity(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner,
        uint256 _quantity
    )
        external
        nonReentrant
        isListed(_nftAddress, _tokenId, _owner)
        validListing(_nftAddress, _tokenId, _owner)
    {
        _buyItemWithQuantity(_nftAddress, _tokenId, _payToken, _owner, _quantity);
    }

    function _buyItemWithQuantity(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        address _owner,
        uint256 _quantity
    ) private {
        Listing storage listedItem = listings[_nftAddress][_tokenId][_owner];

        require(listedItem.payToken == _payToken, "invalid pay token");
        require(_quantity <= listedItem.quantity, "Out of quantity");

        uint256 price = listedItem.pricePerItem.mul(_quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e3);

        IERC20Upgradeable(_payToken).safeTransferFrom(
            _msgSender(),
            feeReceipient,
            feeAmount
        );

        address minter = minters[_nftAddress][_tokenId];
        uint16 royalty = royalties[_nftAddress][_tokenId];
        if (minter != address(0) && royalty != 0) {
            uint256 royaltyFee = price.sub(feeAmount).mul(royalty).div(10000);

            IERC20Upgradeable(_payToken).safeTransferFrom(
                _msgSender(),
                minter,
                royaltyFee
            );

            feeAmount = feeAmount.add(royaltyFee);
        } else {
            minter = collectionRoyalties[_nftAddress].feeRecipient;
            royalty = collectionRoyalties[_nftAddress].royalty;
            if (minter != address(0) && royalty != 0) {
                uint256 royaltyFee = price.sub(feeAmount).mul(royalty).div(
                    10000
                );

                IERC20Upgradeable(_payToken).safeTransferFrom(
                    _msgSender(),
                    minter,
                    royaltyFee
                );

                feeAmount = feeAmount.add(royaltyFee);
            }
        }

        IERC20Upgradeable(_payToken).safeTransferFrom(
            _msgSender(),
            _owner,
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId,
                _quantity,
                bytes("")
            );
        }
        IPixellyBundleMarketplace(addressRegistry.bundleMarketplace())
            .validateItemSold(_nftAddress, _tokenId, _quantity);

        emit ItemSold(
            _owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _payToken,
            getPrice(_payToken),
            price.div(_quantity)
        );

        if (_quantity == listedItem.quantity) {
            delete (listings[_nftAddress][_tokenId][_owner]);
        } else {
            listedItem.quantity = listedItem.quantity - _quantity;
        }
    }

    /// @notice Method for offering item
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Paying token
    /// @param _quantity Quantity of items
    /// @param _pricePerItem Price per item
    /// @param _deadline Offer expiration
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        IERC20Upgradeable _payToken,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _deadline
    ) external offerNotExists(_nftAddress, _tokenId, _msgSender()) {
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155),
            "invalid nft address"
        );

        IPixellyAuction auction = IPixellyAuction(addressRegistry.auction());

        (, , , uint256 startTime, , bool resulted) = auction.auctions(
            _nftAddress,
            _tokenId
        );

        require(
            startTime == 0 || resulted == true,
            "cannot place an offer if auction is going on"
        );

        require(_deadline > _getNow(), "invalid expiration");

        _validPayToken(address(_payToken));

        offers[_nftAddress][_tokenId][_msgSender()] = Offer(
            _payToken,
            _quantity,
            _pricePerItem,
            _deadline
        );

        emit OfferCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            address(_payToken),
            _pricePerItem,
            _deadline
        );
    }

    /// @notice Method for creating counter offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param counteroffer Terms of the counter offer
    /// @param _addressee Addressee of the counter offer
    function createCounterOffer(
        address _nftAddress,
        uint256 _tokenId,
        Offer memory counteroffer,
        address _addressee
    )
        external
        counterOfferNotExists(_nftAddress, _tokenId, _addressee)
        offerExists(_nftAddress, _tokenId, _addressee)
    {
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155),
            "invalid nft address"
        );

        require(counteroffer.deadline > _getNow(), "invalid expiration");

        _noAuctionLive(_nftAddress, _tokenId);

        _validOwner(_nftAddress, _tokenId, _msgSender(), counteroffer.quantity);

        _validPayToken(address(counteroffer.payToken));

        counterOffers[_nftAddress][_tokenId][_addressee] = Offer(
            counteroffer.payToken,
            counteroffer.quantity,
            counteroffer.pricePerItem,
            counteroffer.deadline
        );

        ownerOfERC1155[_nftAddress][_tokenId] = _msgSender();

        emit CounterOfferCreated(
            _msgSender(),
            _addressee,
            _nftAddress,
            _tokenId,
            counteroffer
        );
    }

    /// @notice Method for canceling the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function cancelOffer(address _nftAddress, uint256 _tokenId)
        external
        offerExists(_nftAddress, _tokenId, _msgSender())
    {
        delete (offers[_nftAddress][_tokenId][_msgSender()]);
        emit OfferCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /// @notice Method for refusing the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _creator Creator of the offer
    /// @param _quantity Quantity of items of the offer
    function refuseOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator,
        uint256 _quantity
    ) external offerExists(_nftAddress, _tokenId, _creator) {
        _validOwner(_nftAddress, _tokenId, _msgSender(), _quantity);
        delete (offers[_nftAddress][_tokenId][_creator]);
        emit OfferRefused(_creator, _nftAddress, _tokenId);
    }

    /// @notice Method for canceling the counter offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function cancelCounterOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _addressee
    ) external counterOfferExists(_nftAddress, _tokenId, _addressee) {
        _validOwner(_nftAddress, _tokenId, _msgSender(), _quantity);
        delete (counterOffers[_nftAddress][_tokenId][_addressee]);
        emit CounterOfferCanceled(
            _msgSender(),
            _addressee,
            _nftAddress,
            _tokenId
        );
    }

    /// @notice Method for refusing the counter offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function refuseCounterOffer(address _nftAddress, uint256 _tokenId)
        external
        counterOfferExists(_nftAddress, _tokenId, _msgSender())
    {
        delete (counterOffers[_nftAddress][_tokenId][_msgSender()]);
        address _owner;
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            _owner = nft.ownerOf(_tokenId);
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            _owner = ownerOfERC1155[_nftAddress][_tokenId];
        }
        emit CounterOfferRefused(_owner, _msgSender(), _nftAddress, _tokenId);
    }

    /// @notice Method for accepting the offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _creator Offer creator address
    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external nonReentrant offerExists(_nftAddress, _tokenId, _creator) {
        Offer memory offer = offers[_nftAddress][_tokenId][_creator];

        _validOwner(_nftAddress, _tokenId, _msgSender(), offer.quantity);

        uint256 price = offer.pricePerItem.mul(offer.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e3);

        offer.payToken.safeTransferFrom(_creator, feeReceipient, feeAmount);

        IPixellyRoyaltyRegistry royaltyRegistry = IPixellyRoyaltyRegistry(
            addressRegistry.royaltyRegistry()
        );

        address minter;
        uint256 royaltyAmount;

        (minter, royaltyAmount) = royaltyRegistry.royaltyInfo(
            _nftAddress,
            _tokenId,
            price.sub(feeAmount)
        );

        if (minter != address(0) && royaltyAmount != 0) {
            offer.payToken.safeTransferFrom(_creator, minter, royaltyAmount);

            feeAmount = feeAmount.add(royaltyAmount);
        }

        offer.payToken.safeTransferFrom(
            _creator,
            _msgSender(),
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _msgSender(),
                _creator,
                _tokenId,
                offer.quantity,
                bytes("")
            );
        }
        IPixellyBundleMarketplace(addressRegistry.bundleMarketplace())
            .validateItemSold(_nftAddress, _tokenId, offer.quantity);

        emit ItemSold(
            _msgSender(),
            _creator,
            _nftAddress,
            _tokenId,
            offer.quantity,
            address(offer.payToken),
            getPrice(address(offer.payToken)),
            offer.pricePerItem
        );

        emit OfferCanceled(_creator, _nftAddress, _tokenId);

        delete (listings[_nftAddress][_tokenId][_msgSender()]);
        delete (offers[_nftAddress][_tokenId][_creator]);
    }

    /// @notice Method for accepting the counter offer
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    function acceptCounterOffer(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        counterOfferExists(_nftAddress, _tokenId, _msgSender())
    {
        Offer memory counterOffer = counterOffers[_nftAddress][_tokenId][
            _msgSender()
        ];

        address _owner;

        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            _owner = nft.ownerOf(_tokenId);
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            _owner = ownerOfERC1155[_nftAddress][_tokenId];
        }

        uint256 price = counterOffer.pricePerItem.mul(counterOffer.quantity);
        uint256 feeAmount = price.mul(platformFee).div(1e3);

        counterOffer.payToken.safeTransferFrom(
            _msgSender(),
            feeReceipient,
            feeAmount
        );

        IPixellyRoyaltyRegistry royaltyRegistry = IPixellyRoyaltyRegistry(
            addressRegistry.royaltyRegistry()
        );

        address minter;
        uint256 royaltyAmount;

        (minter, royaltyAmount) = royaltyRegistry.royaltyInfo(
            _nftAddress,
            _tokenId,
            price.sub(feeAmount)
        );

        if (minter != address(0) && royaltyAmount != 0) {
            counterOffer.payToken.safeTransferFrom(
                _msgSender(),
                minter,
                royaltyAmount
            );

            feeAmount = feeAmount.add(royaltyAmount);
        }

        counterOffer.payToken.safeTransferFrom(
            _msgSender(),
            _owner,
            price.sub(feeAmount)
        );

        // Transfer NFT to buyer
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _owner,
                _msgSender(),
                _tokenId,
                counterOffer.quantity,
                bytes("")
            );
        }

        emit ItemSold(
            _owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            counterOffer.quantity,
            address(counterOffer.payToken),
            getPrice(address(counterOffer.payToken)),
            counterOffer.pricePerItem
        );

        emit CounterOfferCanceled(_owner, _msgSender(), _nftAddress, _tokenId);

        delete (listings[_nftAddress][_tokenId][_owner]);
        delete (counterOffers[_nftAddress][_tokenId][_msgSender()]);
    }

    /// @notice Method for setting royalty
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _royalty Royalty
    function registerRoyalty(
        address _nftAddress,
        uint256 _tokenId,
        uint16 _royalty
    ) external {
        require(_royalty <= 10000, "invalid royalty");
        require(_isPixellyNFT(_nftAddress), "invalid nft address");

        _validOwner(_nftAddress, _tokenId, _msgSender(), 1);

        require(
            minters[_nftAddress][_tokenId] == address(0),
            "royalty already set"
        );
        minters[_nftAddress][_tokenId] = _msgSender();
        royalties[_nftAddress][_tokenId] = _royalty;
    }

    /// @notice Method for setting royalty
    /// @param _nftAddress NFT contract address
    /// @param _royalty Royalty
    function registerCollectionRoyalty(
        address _nftAddress,
        address _creator,
        uint16 _royalty,
        address _feeRecipient
    ) external onlyOwner {
        require(_creator != address(0), "invalid creator address");
        require(_royalty <= 10000, "invalid royalty");
        require(
            _royalty == 0 || _feeRecipient != address(0),
            "invalid fee recipient address"
        );
        require(!_isPixellyNFT(_nftAddress), "invalid nft address");

        if (collectionRoyalties[_nftAddress].creator == address(0)) {
            collectionRoyalties[_nftAddress] = CollectionRoyalty(
                _royalty,
                _creator,
                _feeRecipient
            );
        } else {
            CollectionRoyalty storage collectionRoyalty = collectionRoyalties[
                _nftAddress
            ];

            collectionRoyalty.royalty = _royalty;
            collectionRoyalty.feeRecipient = _feeRecipient;
            collectionRoyalty.creator = _creator;
        }
    }

    function _isPixellyNFT(address _nftAddress) internal view returns (bool) {
        return
            addressRegistry.pixellyNFT() == _nftAddress ||
            IPixellyNFTFactory(addressRegistry.factory()).exists(_nftAddress) ||
            IPixellyNFTFactory(addressRegistry.privateFactory()).exists(
                _nftAddress
            ) ||
            IPixellyNFTFactory(addressRegistry.artFactory()).exists(
                _nftAddress
            ) ||
            IPixellyNFTFactory(addressRegistry.privateArtFactory()).exists(
                _nftAddress
            );
    }

    /**
     @notice Method for getting price for pay token
     @param _payToken Paying token
     */
    function getPrice(address _payToken) public view returns (int256) {
        int256 unitPrice;
        uint8 decimals;
        IPixellyPriceFeed priceFeed = IPixellyPriceFeed(
            addressRegistry.priceFeed()
        );

        if (_payToken == address(0)) {
            (unitPrice, decimals) = priceFeed.getPrice(priceFeed.wETH());
        } else {
            (unitPrice, decimals) = priceFeed.getPrice(_payToken);
        }
        if (decimals < 18) {
            unitPrice = unitPrice * (int256(10)**(18 - decimals));
        } else {
            unitPrice = unitPrice / (int256(10)**(decimals - 18));
        }

        return unitPrice;
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint16 the platform fee to set
     */
    function updatePlatformFee(uint16 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        feeReceipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Update PixellyAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IPixellyAddressRegistry(_registry);
    }

    /**
     * @notice Validate and cancel listing
     * @dev Only bundle marketplace can access
     */
    function validateItemSold(
        address _nftAddress,
        uint256 _tokenId,
        address _seller,
        address _buyer
    ) external onlyMarketplace {
        Listing memory item = listings[_nftAddress][_tokenId][_seller];
        if (item.quantity > 0) {
            _cancelListing(_nftAddress, _tokenId, _seller);
        }
        delete (offers[_nftAddress][_tokenId][_buyer]);
        emit OfferCanceled(_buyer, _nftAddress, _tokenId);
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _validPayToken(address _payToken) internal view {
        require(
            _payToken == address(0) ||
                (addressRegistry.tokenRegistry() != address(0) &&
                    IPixellyTokenRegistry(addressRegistry.tokenRegistry())
                        .enabled(_payToken)),
            "invalid pay token"
        );
    }

    function _validOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        uint256 quantity
    ) internal view {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "not owning item");
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_owner, _tokenId) >= quantity,
                "not owning item"
            );
        } else {
            revert("invalid nft address");
        }
    }

    function _noAuctionLive(address _nftAddress, uint256 _tokenId) internal view {
        IPixellyAuction auction = IPixellyAuction(addressRegistry.auction());

        (, , , uint256 startTime, , bool resulted) = auction.auctions(
            _nftAddress,
            _tokenId
        );
        require(
            startTime == 0 || resulted == true,
            "cannot place an offer if auction is going on"
        );
    }

    function _cancelListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) private {
        Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

        _validOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

        delete (listings[_nftAddress][_tokenId][_owner]);
        emit ItemCanceled(_owner, _nftAddress, _tokenId);
    }
}
