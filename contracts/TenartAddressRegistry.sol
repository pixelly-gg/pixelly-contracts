// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TenartAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice TenartNFT contract
    address public tenartNFT;

    /// @notice TenartAuction contract
    address public auction;

    /// @notice TenartMarketplace contract
    address public marketplace;

    /// @notice TenartBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice TenartNFTFactory contract
    address public factory;

    /// @notice TenartNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice TenartArtFactory contract
    address public artFactory;

    /// @notice TenartArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice TenartTokenRegistry contract
    address public tokenRegistry;

    /// @notice TenartPriceFeed contract
    address public priceFeed;

    /// @notice TenartRoyaltyRegistry contract
    address public royaltyRegistry;

    /**
     @notice Update TenartNFT contract
     @dev Only admin
     */
    function updateTenartNFT(address _tenartNFT) external onlyOwner {
        require(
            IERC165(_tenartNFT).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        tenartNFT = _tenartNFT;
    }

    /**
     @notice Update TenartAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update TenartMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update TenartBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update TenartNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update TenartNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update TenartArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update TenartArtFactoryPrivate contract
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
