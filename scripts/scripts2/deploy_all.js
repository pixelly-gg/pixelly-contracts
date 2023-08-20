// to deploy locally
// run: npx hardhat node on a terminal
async function main(network) {
  console.log("network: ", network.name);

  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  const {
    TREASURY_ADDRESS,
    PLATFORM_FEE,
    WRAPPED_TENET,
    ORACLE,
  } = require("../constants");

  // ////////////
  const PixellyNFT = await ethers.getContractFactory("PixellyNFT");
  const pixellyNFT = await PixellyNFT.deploy(
    TREASURY_ADDRESS,
    "2000000000000000000"
  );

  await pixellyNFT.deployed();
  console.log("PixellyNFT deployed at", pixellyNFT.address);
  // ///////////

  ///////////

  const ProxyAdmin = await ethers.getContractFactory('ProxyAdmin');
  const proxyAdmin = await ProxyAdmin.deploy();
  await proxyAdmin.deployed();

  const PROXY_ADDRESS = proxyAdmin.address;

  console.log('ProxyAdmin deployed to:', proxyAdmin.address);

  const AdminUpgradeabilityProxyFactory = await ethers.getContractFactory('AdminUpgradeabilityProxy');
  ///////////////////////

  /////////
  const Marketplace = await ethers.getContractFactory("PixellyMarketplace");
  const marketplaceImpl = await Marketplace.deploy();
  await marketplaceImpl.deployed();

  console.log("PixellyMarketplace deployed to:", marketplaceImpl.address);

  const marketplaceProxy = await AdminUpgradeabilityProxyFactory.deploy(
    marketplaceImpl.address,
    PROXY_ADDRESS,
    []
  );
  await marketplaceProxy.deployed();
  console.log('PixellyMarketplace Proxy deployed at ', marketplaceProxy.address);

  const MARKETPLACE_PROXY_ADDRESS = marketplaceProxy.address;
  const marketplace = await ethers.getContractAt('PixellyMarketplace', marketplaceProxy.address);

  await marketplace.initialize(TREASURY_ADDRESS, PLATFORM_FEE);
  console.log('Marketplace Proxy initialized');
  /////////

  /////////
  const BundleMarketplace = await ethers.getContractFactory(
    "PixellyBundleMarketplace"
  );
  const bundleMarketplaceImpl = await BundleMarketplace.deploy();
    await bundleMarketplaceImpl.deployed();
    console.log('PixellyBundleMarketplace deployed to:', bundleMarketplaceImpl.address);
    
    const bundleMarketplaceProxy = await AdminUpgradeabilityProxyFactory.deploy(
        bundleMarketplaceImpl.address,
        PROXY_ADDRESS,
        []
      );
    await bundleMarketplaceProxy.deployed();
    console.log('Bundle Marketplace Proxy deployed at ', bundleMarketplaceProxy.address);  
    const BUNDLE_MARKETPLACE_PROXY_ADDRESS = bundleMarketplaceProxy.address;
    const bundleMarketplace = await ethers.getContractAt('PixellyBundleMarketplace', bundleMarketplaceProxy.address);
    
    await bundleMarketplace.initialize(TREASURY_ADDRESS, PLATFORM_FEE);
    console.log('Bundle Marketplace Proxy initialized');

  ////////

  ////////
  const Auction = await ethers.getContractFactory('PixellyAuction');
    const auctionImpl = await Auction.deploy();
    await auctionImpl.deployed();
    console.log('PixellyAuction deployed to:', auctionImpl.address);

    const auctionProxy = await AdminUpgradeabilityProxyFactory.deploy(
        auctionImpl.address,
        PROXY_ADDRESS,
        []
      );

    await auctionProxy.deployed();
    console.log('Auction Proxy deployed at ', auctionProxy.address);

    const AUCTION_PROXY_ADDRESS = auctionProxy.address;
    const auction = await ethers.getContractAt('PixellyAuction', auctionProxy.address);
    
    await auction.initialize(TREASURY_ADDRESS);
    console.log('Auction Proxy initialized');

  ////////

  ////////
  const Factory = await ethers.getContractFactory("PixellyNFTFactory");
  const factory = await Factory.deploy(
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS,
    "50000000000000000000"
  );
  await factory.deployed();
  console.log("PixellyNFTFactory deployed to:", factory.address);

  const PrivateFactory = await ethers.getContractFactory(
    "PixellyNFTFactoryPrivate"
  );
  const privateFactory = await PrivateFactory.deploy(
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS,
    "50000000000000000000"
  );
  await privateFactory.deployed();
  console.log("PixellyNFTFactoryPrivate deployed to:", privateFactory.address);
  ////////

  ////////
  const NFTTradable = await ethers.getContractFactory("PixellyNFTTradable");
  const nft = await NFTTradable.deploy(
    "PixellyNFT",
    "PNFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nft.deployed();
  console.log("PixellyNFTTradable deployed to:", nft.address);

  const NFTTradablePrivate = await ethers.getContractFactory(
    "PixellyNFTTradablePrivate"
  );
  const nftPrivate = await NFTTradablePrivate.deploy(
    "IPixellyNFT",
    "IPNFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nftPrivate.deployed();
  console.log("PixellyNFTTradablePrivate deployed to:", nftPrivate.address);
  ////////

  ////////
  const TokenRegistry = await ethers.getContractFactory("PixellyTokenRegistry");
  const tokenRegistry = await TokenRegistry.deploy();

  await tokenRegistry.deployed();

  console.log("PixellyTokenRegistry deployed to", tokenRegistry.address);
  ////////

  ////////
  const AddressRegistry = await ethers.getContractFactory(
    "PixellyAddressRegistry"
  );
  const addressRegistry = await AddressRegistry.deploy();

  await addressRegistry.deployed();

  console.log("PixellyAddressRegistry deployed to", addressRegistry.address);
  const PIXELLY_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  ////////
  const PriceFeed = await ethers.getContractFactory("PixellyPriceFeed");
  
  const priceFeed = await PriceFeed.deploy(PIXELLY_ADDRESS_REGISTRY, WRAPPED_TENET);

  await priceFeed.deployed();

  console.log("PixellyPriceFeed deployed to", priceFeed.address);
  ////////

  ////////
  const ArtTradable = await ethers.getContractFactory("PixellyArtTradable");
  const artTradable = await ArtTradable.deploy(
    "PixellyArt",
    "PART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradable.deployed();
  console.log("PixellyArtTradable deployed to:", artTradable.address);

  const ArtTradablePrivate = await ethers.getContractFactory(
    "PixellyArtTradablePrivate"
  );
  const artTradablePrivate = await ArtTradablePrivate.deploy(
    "PixellyArt",
    "PART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradablePrivate.deployed();
  console.log(
    "PixellyArtTradablePrivate deployed to:",
    artTradablePrivate.address
  );
  ////////

  ////////
  const ArtFactory = await ethers.getContractFactory("PixellyArtFactory");
  const artFactory = await ArtFactory.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS,
    "50000000000000000000"
  );
  await artFactory.deployed();
  console.log("PixellyArtFactory deployed to:", artFactory.address);

  const ArtFactoryPrivate = await ethers.getContractFactory(
    "PixellyArtFactoryPrivate"
  );
  const artFactoryPrivate = await ArtFactoryPrivate.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS,
    "50000000000000000000"
  );
  await artFactoryPrivate.deployed();
  console.log("PixellyArtFactoryPrivate deployed to:", artFactoryPrivate.address);
  ////////

  await marketplace.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);
  await bundleMarketplace.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);

  await auction.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);

  await addressRegistry.updatePixellyNFT(pixellyNFT.address);
  await addressRegistry.updateAuction(auction.address);
  await addressRegistry.updateMarketplace(marketplace.address);
  await addressRegistry.updateBundleMarketplace(bundleMarketplace.address);
  await addressRegistry.updateNFTFactory(factory.address);
  await addressRegistry.updateTokenRegistry(tokenRegistry.address);
  await addressRegistry.updatePriceFeed(priceFeed.address);
  await addressRegistry.updateArtFactory(artFactory.address);

  await priceFeed.registerOracle(WRAPPED_TENET, ORACLE);

  await tokenRegistry.add(WRAPPED_TENET);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
