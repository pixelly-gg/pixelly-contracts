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
  // const TenartNFT = await ethers.getContractFactory("TenartNFT");
  // const tenartNFT = await TenartNFT.deploy(
  //   TREASURY_ADDRESS,
  //   "2000000000000000000"
  // );

  // await tenartNFT.deployed();
  // console.log("TenartNFT deployed at", tenartNFT.address);
  // ///////////

  /////////
  const Marketplace = await ethers.getContractFactory("TenartMarketplace");

  const marketplaceImpl = await upgrades.deployProxy(
    Marketplace,
    [TREASURY_ADDRESS, PLATFORM_FEE],
    {
      initializer: "initialize",
    }
  );

  const MARKETPLACE_PROXY_ADDRESS = marketplaceImpl.address;

  console.log("TenartMarketplace deployed to:", marketplaceImpl.address);
  /////////

  /////////
  const BundleMarketplace = await ethers.getContractFactory(
    "TenartBundleMarketplace"
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
    "TenartBundleMarketplace deployed to:",
    bundleMarketplaceImpl.address
  );

  ////////

  ////////
  const Auction = await ethers.getContractFactory("TenartAuction");
  const auctionImpl = await upgrades.deployProxy(
    Auction,
    [TREASURY_ADDRESS, 1],
    {
      initializer: "store",
    }
  );
  console.log("TenartAuction deployed to:", auctionImpl.address);
  const AUCTION_PROXY_ADDRESS = auctionImpl.address;

  ////////

  ////////
  const Factory = await ethers.getContractFactory("TenartNFTFactory");
  const factory = await Factory.deploy(
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await factory.deployed();
  console.log("TenartNFTFactory deployed to:", factory.address);

  const PrivateFactory = await ethers.getContractFactory(
    "TenartNFTFactoryPrivate"
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
  console.log("TenartNFTFactoryPrivate deployed to:", privateFactory.address);
  ////////

  ////////
  const NFTTradable = await ethers.getContractFactory("TenartNFTTradable");
  const nft = await NFTTradable.deploy(
    "TenartNFT",
    "ANFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nft.deployed();
  console.log("TenartNFTTradable deployed to:", nft.address);

  const NFTTradablePrivate = await ethers.getContractFactory(
    "TenartNFTTradablePrivate"
  );
  const nftPrivate = await NFTTradablePrivate.deploy(
    "ITenartNFT",
    "IANFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nftPrivate.deployed();
  console.log("TenartNFTTradablePrivate deployed to:", nftPrivate.address);
  ////////

  ////////
  const TokenRegistry = await ethers.getContractFactory("TenartTokenRegistry");
  const tokenRegistry = await TokenRegistry.deploy();

  await tokenRegistry.deployed();

  console.log("TenartTokenRegistry deployed to", tokenRegistry.address);
  ////////

  ////////
  const AddressRegistry = await ethers.getContractFactory(
    "TenartAddressRegistry"
  );
  const addressRegistry = await AddressRegistry.deploy();

  await addressRegistry.deployed();

  console.log("TenartAddressRegistry deployed to", addressRegistry.address);
  const TENART_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  ////////
  const PriceFeed = await ethers.getContractFactory("TenartPriceFeed");
  const WRAPPED_ETH =
    network.name === "mainnet" ? WRAPPED_ETH_MAINNET : WRAPPED_ETH_TESTNET;
  const priceFeed = await PriceFeed.deploy(TENART_ADDRESS_REGISTRY, WRAPPED_ETH);

  await priceFeed.deployed();

  console.log("TenartPriceFeed deployed to", priceFeed.address);
  ////////

  ////////
  const ArtTradable = await ethers.getContractFactory("TenartArtTradable");
  const artTradable = await ArtTradable.deploy(
    "TenartArt",
    "AART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradable.deployed();
  console.log("TenartArtTradable deployed to:", artTradable.address);

  const ArtTradablePrivate = await ethers.getContractFactory(
    "TenartArtTradablePrivate"
  );
  const artTradablePrivate = await ArtTradablePrivate.deploy(
    "TenartArt",
    "AART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradablePrivate.deployed();
  console.log(
    "TenartArtTradablePrivate deployed to:",
    artTradablePrivate.address
  );
  ////////

  ////////
  const ArtFactory = await ethers.getContractFactory("TenartArtFactory");
  const artFactory = await ArtFactory.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactory.deployed();
  console.log("TenartArtFactory deployed to:", artFactory.address);

  const ArtFactoryPrivate = await ethers.getContractFactory(
    "TenartArtFactoryPrivate"
  );
  const artFactoryPrivate = await ArtFactoryPrivate.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactoryPrivate.deployed();
  console.log("TenartArtFactoryPrivate deployed to:", artFactoryPrivate.address);
  ////////

  await marketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);

  await auctionImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);

  await addressRegistry.updateTenartNFT(tenartNFT.address);
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
