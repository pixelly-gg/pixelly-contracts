// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AgoraAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice AgoraNFT contract
    address public agoraNFT;

    /// @notice AgoraAuction contract
    address public auction;

    /// @notice AgoraMarketplace contract
    address public marketplace;

    /// @notice AgoraBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice AgoraNFTFactory contract
    address public factory;

    /// @notice AgoraNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice AgoraArtFactory contract
    address public artFactory;

    /// @notice AgoraArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice AgoraTokenRegistry contract
    address public tokenRegistry;

    /// @notice AgoraPriceFeed contract
    address public priceFeed;

    /// @notice AgoraRoyaltyRegistry contract
    address public royaltyRegistry;

    /**
     @notice Update AgoraNFT contract
     @dev Only admin
     */
    function updateAgoraNFT(address _agoraNFT) external onlyOwner {
        require(
            IERC165(_agoraNFT).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        agoraNFT = _agoraNFT;
    }

    /**
     @notice Update AgoraAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update AgoraMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update AgoraBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update AgoraNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update AgoraNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update AgoraArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update AgoraArtFactoryPrivate contract
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
