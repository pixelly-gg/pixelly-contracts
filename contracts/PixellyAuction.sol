// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IPixellyAddressRegistry {
    function pixellyNFT() external view returns (address);

    function marketplace() external view returns (address);

    function bundleMarketplace() external view returns (address);

    function tokenRegistry() external view returns (address);

    function royaltyRegistry() external view returns (address);
}

interface IPixellyMarketplace {
    function getPrice(address) external view returns (int256);
}

interface IPixellyBundleMarketplace {
    function validateItemSold(
        address,
        uint256,
        uint256
    ) external;
}

interface IPixellyTokenRegistry {
    function enabled(address) external returns (bool);
}

interface IPixellyRoyaltyRegistry {
    function royaltyInfo(
        address _collection,
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);
}

/**
 * @notice Secondary sale auction contract for NFTs
 */
contract PixellyAuction is OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver {
    using SafeMath for uint256;
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20;

    /// @notice Event emitted only on construction. To be used by indexers
    event PixellyAuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken
    );

    event UpdateAuctionEndTime(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 endTime
    );

    event UpdateAuctionStartTime(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 startTime
    );

    event UpdateAuctionReservePrice(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 reservePrice
    );

    event UpdatePlatformFee(uint256 platformFee);

    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    event UpdateMinBidIncrement(uint256 minBidIncrement);

    event UpdateBidWithdrawalLockTime(uint256 bidWithdrawalLockTime);

    event BidPlaced(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        address oldOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        address payToken,
        int256 unitPrice,
        uint256 winningBid
    );

    event AuctionCancelled(address indexed nftAddress, uint256 indexed tokenId);

    /// @notice Parameters of an auction
    struct Auction {
        address owner;
        address payToken;
        uint256 minBid;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bit on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    /// @notice ERC721 Address -> Token ID -> Auction Parameters
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice ERC721 Address -> Token ID -> highest bidder info (if a bid has been received)
    mapping(address => mapping(uint256 => HighestBid)) public highestBids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime;

    /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public platformFee;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    /// @notice Address registry
    IPixellyAddressRegistry public addressRegistry;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    /// @notice Used to track and set the maximum allowed auction time (_startTimestamp + maxAuctionLength)
    uint256 public constant maxAuctionLength = 30 days;

    modifier whenNotPaused() {
        require(!isPaused, "contract paused");
        _;
    }

    modifier onlyMarketplace() {
        require(
            addressRegistry.marketplace() == _msgSender() ||
                addressRegistry.bundleMarketplace() == _msgSender(),
            "not marketplace contract"
        );
        _;
    }

    modifier onlyNotContract() {
        require(_msgSender() == tx.origin);
        _;
    }

    /// @notice Contract initializer
    function initialize(
        address payable _platformFeeRecipient,
        uint256 _minBidIncrement
    ) public initializer {
        require(
            _platformFeeRecipient != address(0),
            "PixellyAuction: Invalid Platform Fee Recipient"
        );

        platformFeeRecipient = _platformFeeRecipient;
        minBidIncrement = _minBidIncrement;
        bidWithdrawalLockTime = 20 minutes;
        platformFee = 25;
        emit PixellyAuctionContractDeployed();

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     @notice Creates a new auction for a given item
     @dev Only the owner of item can create an auction and must have approved the contract
     @dev In addition to owning the item, the sender also has to have the MINTER role.
     @dev End time for the auction must be in the future.
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        bool minBidReserve,
        uint256 _endTimestamp
    ) external whenNotPaused {
        // Ensure this contract is approved to move the token
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                IERC721(_nftAddress).isApprovedForAll(
                    _msgSender(),
                    address(this)
                ),
            "not owner and or contract not approved"
        );
        require(
            (addressRegistry.tokenRegistry() != address(0) &&
                IPixellyTokenRegistry(addressRegistry.tokenRegistry()).enabled(
                    _payToken
                )),
            "invalid pay token"
        );

        // Adds hard limits to cap the maximum auction length
        require(
            _endTimestamp <= (_startTimestamp + maxAuctionLength),
            "Auction time exceeds maximum length"
        );

        _createAuction(
            _nftAddress,
            _tokenId,
            _payToken,
            _reservePrice,
            _startTimestamp,
            minBidReserve,
            _endTimestamp
        );
    }

    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _bidAmount Bid amount
     */
    function placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidAmount
    ) external nonReentrant whenNotPaused onlyNotContract {
        // Check the auction to see if this is a valid bid
        Auction memory auction = auctions[_nftAddress][_tokenId];
        require(auction.endTime > 0, "No auction exists");

        // Ensure auction is in flight
        require(
            _getNow() >= auction.startTime && _getNow() <= auction.endTime,
            "bidding outside of the auction window"
        );
        require(
            auction.payToken != address(0),
            "ERC20 method used for ETH auction"
        );

        _placeBid(_nftAddress, _tokenId, _bidAmount);
    }

    function _placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidAmount
    ) internal whenNotPaused {
        Auction storage auction = auctions[_nftAddress][_tokenId];

        if (auction.minBid == auction.reservePrice) {
            require(
                _bidAmount >= auction.reservePrice,
                "bid cannot be lower than reserve price"
            );
        }

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        uint256 minBidRequired = highestBid.bid.add(minBidIncrement);

        require(
            _bidAmount >= minBidRequired,
            "failed to outbid highest bidder"
        );

        IERC20 payToken = IERC20(auction.payToken);
        require(
            payToken.transferFrom(_msgSender(), address(this), _bidAmount),
            "insufficient balance or not approved"
        );

        if (auction.endTime - _getNow() < 600) {
            auction.endTime += 600;
        }

        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );
        }

        // assign top bidder and bid time
        highestBid.bidder = _msgSender();
        highestBid.bid = _bidAmount;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_nftAddress, _tokenId, _msgSender(), _bidAmount);
    }

    /**
     @notice Allows the hightest bidder to withdraw the bid (after 12 hours post auction's end) 
     @dev Only callable by the existing top bidder
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function withdrawBid(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];

        // Ensure highest bidder is the caller
        require(
            highestBid.bidder == _msgSender(),
            "you are not the highest bidder"
        );

        uint256 _endTime = auctions[_nftAddress][_tokenId].endTime;

        require(
            _getNow() > _endTime && (_getNow() - _endTime >= 86400),
            "can withdraw only after 12 hours (after auction ended)"
        );

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_nftAddress][_tokenId];

        // Refund the top bidder
        _refundHighestBidder(_nftAddress, _tokenId, _msgSender(), previousBid);

        emit BidWithdrawn(_nftAddress, _tokenId, _msgSender(), previousBid);
    }

    //////////
    // Admin /
    //////////

    /**
     @notice Closes a finished auction and rewards the highest bidder
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function resultAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Store auction owner
        address seller = auction.owner;

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;

        // Ensure _msgSender() is either auction winner or seller
        require(
            _msgSender() == winner || _msgSender() == seller || _msgSender() == operator(),
            "_msgSender() must be auction winner or seller"
        );

        // Ensure this contract is the owner of the item
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
            "address(this) must be the item owner"
        );
        // Check the auction real
        require(auction.endTime > 0, "no auction exists");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Ensure there is a winner
        require(winner != address(0), "no open bids");

        require(
            winningBid >= auction.reservePrice,
            "highest bid is below reservePrice"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC721(_nftAddress).isApprovedForAll(_msgSender(), address(this)),
            "auction not approved"
        );

        _resultAuction(_nftAddress, _tokenId, winner, winningBid);
    }

    /**
     @notice Closes a finished auction and rewards the highest bidder
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function _resultAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid
    ) internal {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];
        // Result the auction
        auction.resulted = true;

        // Clean up the highest bid
        delete highestBids[_nftAddress][_tokenId];
        {
            uint256 payAmount;

            if (_winningBid > auction.reservePrice) {
                // Work out platform fee
                uint256 platformFees = _winningBid.mul(platformFee).div(1000);
                // Send platform fee
                IERC20 payToken = IERC20(auction.payToken);
                require(
                    payToken.transfer(platformFeeRecipient, platformFees),
                    "failed to send platform fee"
                );

                // Send remaining to designer
                payAmount = _winningBid.sub(platformFees);
            } else {
                payAmount = _winningBid;
            }
            IPixellyRoyaltyRegistry royaltyRegistry = IPixellyRoyaltyRegistry(
                addressRegistry.royaltyRegistry()
            );

            address minter;
            uint256 royaltyAmount;

            (minter, royaltyAmount) = royaltyRegistry.royaltyInfo(
                _nftAddress,
                _tokenId,
                payAmount
            );

            if (minter != address(0) && royaltyAmount != 0) {
                IERC20 payToken = IERC20(auction.payToken);
                require(
                    payToken.transfer(minter, royaltyAmount),
                    "failed to send the royalties"
                );

                payAmount = payAmount.sub(royaltyAmount);
            }
            if (payAmount > 0) {
                IERC20 payToken = IERC20(auction.payToken);
                require(
                    payToken.transfer(auction.owner, payAmount),
                    "failed to send the owner the auction balance"
                );
            }
        }
        // Transfer the token to the winner
        IERC721(_nftAddress).safeTransferFrom(address(this), _winner, _tokenId);

        IPixellyBundleMarketplace(addressRegistry.bundleMarketplace())
            .validateItemSold(_nftAddress, _tokenId, uint256(1));

        emit AuctionResulted(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _winner,
            auction.payToken,
            IPixellyMarketplace(addressRegistry.marketplace()).getPrice(
                auction.payToken
            ),
            _winningBid
        );

        // Remove auction
        delete auctions[_nftAddress][_tokenId];
    }

    /**
     @notice Results an auction that failed to meet the auction.reservePrice
     @dev Only admin or smart contract
     @dev Auction can only be fail-resulted if the auction has expired and the auction.reservePrice has not been met
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function resultFailedAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Store auction owner
        address seller = auction.owner;

        // Ensure this contract is the owner of the item
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
            "address(this) must be the item owner"
        );

        // Check if the auction exists
        require(auction.endTime > 0, "no auction exists");

        // Check if the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address payable topBidder = highestBid.bidder;
        uint256 topBid = highestBid.bid;

        // Ensure _msgSender() is either auction topBidder or seller
        require(
            _msgSender() == topBidder || _msgSender() == seller || _msgSender() == operator(),
            "_msgSender() must be auction topBidder or seller"
        );

        // Ensure the topBid is less than the auction.reservePrice
        require(topBidder != address(0), "no open bids");
        require(
            topBid < auction.reservePrice,
            "highest bid is >= reservePrice"
        );

        _cancelAuction(_nftAddress, _tokenId, seller);
    }

    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only item owner
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check valid and not resulted
        Auction memory auction = auctions[_nftAddress][_tokenId];

        require(IERC721(_nftAddress).ownerOf(_tokenId) == address(this) && 
            (_msgSender() == auction.owner || _msgSender() == operator()), "sender must be owner"
        );
        // Check auction is real
        require(auction.endTime > 0, "no auction exists");
        // Check auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Gets info on auction and ensures highest bid is less than the reserve price
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        require(
            highestBid.bid < auction.reservePrice,
            "Highest bid is currently above reserve price"
        );

        _cancelAuction(_nftAddress, _tokenId, _msgSender());
    }

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement)
        external
        onlyOwner
    {
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }

    /**
     @notice Update the global bid withdrawal lockout time
     @dev Only admin
     @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
        external
        onlyOwner
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit UpdateBidWithdrawalLockTime(_bidWithdrawalLockTime);
    }

    /**
     @notice Update the current reserve price for an auction
     @dev Only admin
     @dev Auction must exist
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice New Ether reserve price (WEI value)
     */
    function updateAuctionReservePrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        // Store the current reservePrice
        uint256 currentReserve = auction.reservePrice;

        // Ensures the sender owns the auction and the item is currently in escrow
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == address(this) &&
                _msgSender() == auction.owner,
            "Sender must be item owner and NFT must be in escrow"
        );

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        require(auction.endTime > 0, "no auction exists");

        // Ensures the reserve price can only be decreased and never increased
        require(
            _reservePrice < currentReserve,
            "Reserve price can only be decreased"
        );

        auction.reservePrice = _reservePrice;
        emit UpdateAuctionReservePrice(
            _nftAddress,
            _tokenId,
            auction.payToken,
            _reservePrice
        );
    }

    /**
     @notice Update the current start time for an auction
     @dev Only admin
     @dev Auction must exist
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startTime
    ) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];

        require(_msgSender() == auction.owner, "sender must be owner");

        require(_startTime > 0, "invalid start time");

        require(auction.startTime + 60 > _getNow(), "auction already started");

        require(
            _startTime + 300 < auction.endTime,
            "start time should be less than end time (by 5 minutes)"
        );

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        require(auction.endTime > 0, "no auction exists");

        auction.startTime = _startTime;
        emit UpdateAuctionStartTime(_nftAddress, _tokenId, _startTime);
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
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
        require(_platformFeeRecipient != address(0), "zero address");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Update PixellyAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IPixellyAddressRegistry(_registry);
    }

    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getAuction(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address _owner,
            address _payToken,
            uint256 _reservePrice,
            uint256 _startTime,
            uint256 _endTime,
            bool _resulted,
            uint256 minBid
        )
    {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        return (
            auction.owner,
            auction.payToken,
            auction.reservePrice,
            auction.startTime,
            auction.endTime,
            auction.resulted,
            auction.minBid
        );
    }

    /**
     @notice Method for getting all info about the highest bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getHighestBidder(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address payable _bidder,
            uint256 _bid,
            uint256 _lastBidTime
        )
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        return (highestBid.bidder, highestBid.bid, highestBid.lastBidTime);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Private method doing the heavy lifting of creating an auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function _createAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        bool minBidReserve,
        uint256 _endTimestamp
    ) private returns (bytes4) {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(
            auctions[_nftAddress][_tokenId].endTime == 0,
            "auction already started"
        );

        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp >= _startTimestamp + 300,
            "end time must be greater than start (by 5 minutes)"
        );

        require(_startTimestamp > _getNow(), "invalid start time");

        uint256 minimumBid = 0;

        if (minBidReserve) {
            minimumBid = _reservePrice;
        }

        // Transfer the token to the contract to be held in escrow
        IERC721(_nftAddress).safeTransferFrom(
            IERC721(_nftAddress).ownerOf(_tokenId),
            address(this),
            _tokenId
        );

        // Setup the auction
        auctions[_nftAddress][_tokenId] = Auction({
            owner: _msgSender(),
            payToken: _payToken,
            minBid: minimumBid,
            reservePrice: _reservePrice,
            startTime: _startTimestamp,
            endTime: _endTimestamp,
            resulted: false
        });

        emit AuctionCreated(_nftAddress, _tokenId, _payToken);
    }

    function _cancelAuction(address _nftAddress, uint256 _tokenId, address owner) private {
        // refund existing top bidder if found
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );

            // Clear up highest bid
            delete highestBids[_nftAddress][_tokenId];
        }

        // Remove auction and top bidder
        delete auctions[_nftAddress][_tokenId];

        // Transfer the NFT ownership back to _msgSender()
        IERC721(_nftAddress).safeTransferFrom(
            IERC721(_nftAddress).ownerOf(_tokenId),
            owner,
            _tokenId
        );

        emit AuctionCancelled(_nftAddress, _tokenId);
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether or Mona amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(
        address _nftAddress,
        uint256 _tokenId,
        address payable _currentHighestBidder,
        uint256 _currentHighestBid
    ) private {
        Auction memory auction = auctions[_nftAddress][_tokenId];

        IERC20 payToken = IERC20(auction.payToken);
        require(
            payToken.transfer(_currentHighestBidder, _currentHighestBid),
            "failed to refund previous bidder"
        );
        emit BidRefunded(
            _nftAddress,
            _tokenId,
            _currentHighestBidder,
            _currentHighestBid
        );
    }

    /**
     * @notice Reclaims ERC20 Compatible tokens for entire balance
     * @dev Only access controls admin
     * @param _tokenContract The address of the token contract
     */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_msgSender(), balance), "Transfer failed");
    }

    function operatorSlot() public pure returns (bytes32) {
        return bytes32(uint256(keccak256('pixelly.auction.operator')) - 1);
    }

    function operator() public view returns (address opt) {
        bytes32 slot = operatorSlot();
        assembly {
            opt := sload(slot)
        }
    }

    function setOperator(address newOpt) external onlyOwner {
        bytes32 slot = operatorSlot();

        assembly {
            sstore(slot, newOpt)
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Only owner function, to assure a good transition between the two contracts

    function endAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Store auction owner
        address seller = auction.owner;

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;

        // Check the auction real
        require(auction.endTime > 0, "no auction exists");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Ensure there is a winner
        require(winner != address(0), "no open bids");
        require(
            winningBid >= auction.reservePrice,
            "highest bid is below reservePrice"
        );

        _endAuction(_nftAddress, _tokenId, winner, winningBid);
    }

    function _endAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid
    ) internal {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Result the auction
        auction.resulted = true;

        // Clean up the highest bid
        delete highestBids[_nftAddress][_tokenId];

        uint256 payAmount;

        if (_winningBid > auction.reservePrice) {
            // Work out platform fee
            uint256 platformFees = _winningBid.mul(platformFee).div(1000);
            // Send platform fee
            IERC20 payToken = IERC20(auction.payToken);
            require(
                payToken.transfer(platformFeeRecipient, platformFees),
                "failed to send platform fee"
            );

            // Send remaining to designer
            payAmount = _winningBid.sub(platformFees);
        } else {
            payAmount = _winningBid;
        }
        IPixellyRoyaltyRegistry royaltyRegistry = IPixellyRoyaltyRegistry(
            addressRegistry.royaltyRegistry()
        );

        address minter;
        uint256 royaltyAmount;

        (minter, royaltyAmount) = royaltyRegistry.royaltyInfo(
            _nftAddress,
            _tokenId,
            payAmount
        );

        if (minter != address(0) && royaltyAmount != 0) {
            IERC20 payToken = IERC20(auction.payToken);
            require(
                payToken.transfer(minter, royaltyAmount),
                "failed to send the royalties"
            );

            payAmount = payAmount.sub(royaltyAmount);
        }
        if (payAmount > 0) {
            IERC20 payToken = IERC20(auction.payToken);
            require(
                payToken.transfer(auction.owner, payAmount),
                "failed to send the owner the auction balance"
            );
        }

        // Transfer the token to the winner
        IERC721(_nftAddress).safeTransferFrom(auction.owner, _winner, _tokenId);

        IPixellyBundleMarketplace(addressRegistry.bundleMarketplace())
            .validateItemSold(_nftAddress, _tokenId, uint256(1));

        emit AuctionResulted(
            auction.owner,
            _nftAddress,
            _tokenId,
            _winner,
            auction.payToken,
            IPixellyMarketplace(addressRegistry.marketplace()).getPrice(
                auction.payToken
            ),
            _winningBid
        );

        // Remove auction
        delete auctions[_nftAddress][_tokenId];
    }

    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only item owner
     @dev USE ONLY FOR OLD AUCTIONS NOT ENDED
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuctionOwner(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        // Check valid and not resulted
        Auction memory auction = auctions[_nftAddress][_tokenId];

        // Check auction is real
        require(auction.endTime > 0, "no auction exists");
        // Check auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Gets info on auction and ensures highest bid is less than the reserve price
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        require(
            highestBid.bid < auction.reservePrice,
            "Highest bid is currently above reserve price"
        );
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );

            // Clear up highest bid
            delete highestBids[_nftAddress][_tokenId];
        }

        // Remove auction and top bidder
        delete auctions[_nftAddress][_tokenId];

        emit AuctionCancelled(_nftAddress, _tokenId);
    }
}
