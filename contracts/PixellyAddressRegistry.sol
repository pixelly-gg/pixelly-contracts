// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixellyAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice PixellyNFT contract
    address public tenartNFT;

    /// @notice PixellyAuction contract
    address public auction;

    /// @notice PixellyMarketplace contract
    address public marketplace;

    /// @notice PixellyBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice PixellyNFTFactory contract
    address public factory;

    /// @notice PixellyNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice PixellyArtFactory contract
    address public artFactory;

    /// @notice PixellyArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice PixellyTokenRegistry contract
    address public tokenRegistry;

    /// @notice PixellyPriceFeed contract
    address public priceFeed;

    /// @notice PixellyRoyaltyRegistry contract
    address public royaltyRegistry;

    /**
     @notice Update PixellyNFT contract
     @dev Only admin
     */
    function updatePixellyNFT(address _tenartNFT) external onlyOwner {
        require(
            IERC165(_tenartNFT).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        tenartNFT = _tenartNFT;
    }

    /**
     @notice Update PixellyAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update PixellyMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update PixellyBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update PixellyNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update PixellyNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update PixellyArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update PixellyArtFactoryPrivate contract
     @dev Only admin
     */
    function updateArtFactoryPrivate(address _privateArtFactory)
        external
        onlyOwner
    {
        privateArtFactory = _privateArtFactory;
    }

    /**
     @notice Update token registry contract
     @dev Only admin
     */
    function updateTokenRegistry(address _tokenRegistry) external onlyOwner {
        tokenRegistry = _tokenRegistry;
    }

    /**
     @notice Update price feed contract
     @dev Only admin
     */
    function updatePriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }

    /**
     @notice Update royalty registry contract
     @dev Only admin
     */
    function updateRoyaltyRegistry(address _royaltyRegistry)
        external
        onlyOwner
    {
        royaltyRegistry = _royaltyRegistry;
    }
}
