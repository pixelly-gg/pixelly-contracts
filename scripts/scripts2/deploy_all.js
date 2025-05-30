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
    WRAPPED_ETH_MAINNET,
    WRAPPED_ETH_TESTNET,
  } = require("../constants");

  // ////////////
  // const PixellyNFT = await ethers.getContractFactory("PixellyNFT");
  // const pixellyNFT = await PixellyNFT.deploy(
  //   TREASURY_ADDRESS,
  //   "2000000000000000000"
  // );

  // await pixellyNFT.deployed();
  // console.log("PixellyNFT deployed at", pixellyNFT.address);
  // ///////////

  /////////
  const Marketplace = await ethers.getContractFactory("PixellyMarketplace");

  const marketplaceImpl = await upgrades.deployProxy(
    Marketplace,
    [TREASURY_ADDRESS, PLATFORM_FEE],
    {
      initializer: "initialize",
    }
  );

  const MARKETPLACE_PROXY_ADDRESS = marketplaceImpl.address;

  console.log("PixellyMarketplace deployed to:", marketplaceImpl.address);
  /////////

  /////////
  const BundleMarketplace = await ethers.getContractFactory(
    "PixellyBundleMarketplace"
  );
  const bundleMarketplaceImpl = await upgrades.deployProxy(
    BundleMarketplace,
    [TREASURY_ADDRESS, PLATFORM_FEE],
    {
      initializer: "store",
    }
  );

  const BUNDLE_MARKETPLACE_PROXY_ADDRESS = bundleMarketplaceImpl.address;

  console.log(
    "PixellyBundleMarketplace deployed to:",
    bundleMarketplaceImpl.address
  );

  ////////

  ////////
  const Auction = await ethers.getContractFactory("PixellyAuction");
  const auctionImpl = await upgrades.deployProxy(
    Auction,
    [TREASURY_ADDRESS, 1],
    {
      initializer: "store",
    }
  );
  console.log("PixellyAuction deployed to:", auctionImpl.address);
  const AUCTION_PROXY_ADDRESS = auctionImpl.address;

  ////////

  ////////
  const Factory = await ethers.getContractFactory("PixellyNFTFactory");
  const factory = await Factory.deploy(
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
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
    "25000000000000000000"
  );
  await privateFactory.deployed();
  console.log("PixellyNFTFactoryPrivate deployed to:", privateFactory.address);
  ////////

  ////////
  const NFTTradable = await ethers.getContractFactory("PixellyNFTTradable");
  const nft = await NFTTradable.deploy(
    "PixellyNFT",
    "TNFT",
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
    "ITNFT",
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
  const WRAPPED_ETH =
    network.name === "mainnet" ? WRAPPED_ETH_MAINNET : WRAPPED_ETH_TESTNET;
  const priceFeed = await PriceFeed.deploy(PIXELLY_ADDRESS_REGISTRY, WRAPPED_ETH);

  await priceFeed.deployed();

  console.log("PixellyPriceFeed deployed to", priceFeed.address);
  ////////

  ////////
  const ArtTradable = await ethers.getContractFactory("PixellyArtTradable");
  const artTradable = await ArtTradable.deploy(
    "PixellyArt",
    "AART",
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
    "AART",
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
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactory.deployed();
  console.log("PixellyArtFactory deployed to:", artFactory.address);

  const ArtFactoryPrivate = await ethers.getContractFactory(
    "PixellyArtFactoryPrivate"
  );
  const artFactoryPrivate = await ArtFactoryPrivate.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactoryPrivate.deployed();
  console.log("PixellyArtFactoryPrivate deployed to:", artFactoryPrivate.address);
  ////////

  await marketplaceImpl.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);

  await auctionImpl.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);

  await addressRegistry.updatePixellyNFT(pixellyNFT.address);
  await addressRegistry.updateAuction(auctionImpl.address);
  await addressRegistry.updateMarketplace(marketplaceImpl.address);
  await addressRegistry.updateBundleMarketplace(bundleMarketplaceImpl.address);
  await addressRegistry.updateNFTFactory(factory.address);
  await addressRegistry.updateTokenRegistry(tokenRegistry.address);
  await addressRegistry.updatePriceFeed(priceFeed.address);
  await addressRegistry.updateArtFactory(artFactory.address);

  await tokenRegistry.add(WRAPPED_ETH);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
