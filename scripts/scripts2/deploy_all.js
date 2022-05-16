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
  // const AgoraNFT = await ethers.getContractFactory("AgoraNFT");
  // const agoraNFT = await AgoraNFT.deploy(
  //   TREASURY_ADDRESS,
  //   "2000000000000000000"
  // );

  // await agoraNFT.deployed();
  // console.log("AgoraNFT deployed at", agoraNFT.address);
  // ///////////

  /////////
  const Marketplace = await ethers.getContractFactory("AgoraMarketplace");

  const marketplaceImpl = await upgrades.deployProxy(
    Marketplace,
    [TREASURY_ADDRESS, PLATFORM_FEE],
    {
      initializer: "initialize",
    }
  );

  const MARKETPLACE_PROXY_ADDRESS = marketplaceImpl.address;

  console.log("AgoraMarketplace deployed to:", marketplaceImpl.address);
  /////////

  /////////
  const BundleMarketplace = await ethers.getContractFactory(
    "AgoraBundleMarketplace"
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
    "AgoraBundleMarketplace deployed to:",
    bundleMarketplaceImpl.address
  );

  ////////

  ////////
  const Auction = await ethers.getContractFactory("AgoraAuction");
  const auctionImpl = await upgrades.deployProxy(
    Auction,
    [TREASURY_ADDRESS, 1],
    {
      initializer: "store",
    }
  );
  console.log("AgoraAuction deployed to:", auctionImpl.address);
  const AUCTION_PROXY_ADDRESS = auctionImpl.address;

  ////////

  ////////
  const Factory = await ethers.getContractFactory("AgoraNFTFactory");
  const factory = await Factory.deploy(
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await factory.deployed();
  console.log("AgoraNFTFactory deployed to:", factory.address);

  const PrivateFactory = await ethers.getContractFactory(
    "AgoraNFTFactoryPrivate"
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
  console.log("AgoraNFTFactoryPrivate deployed to:", privateFactory.address);
  ////////

  ////////
  const NFTTradable = await ethers.getContractFactory("AgoraNFTTradable");
  const nft = await NFTTradable.deploy(
    "AgoraNFT",
    "ANFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nft.deployed();
  console.log("AgoraNFTTradable deployed to:", nft.address);

  const NFTTradablePrivate = await ethers.getContractFactory(
    "AgoraNFTTradablePrivate"
  );
  const nftPrivate = await NFTTradablePrivate.deploy(
    "IAgoraNFT",
    "IANFT",
    AUCTION_PROXY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nftPrivate.deployed();
  console.log("AgoraNFTTradablePrivate deployed to:", nftPrivate.address);
  ////////

  ////////
  const TokenRegistry = await ethers.getContractFactory("AgoraTokenRegistry");
  const tokenRegistry = await TokenRegistry.deploy();

  await tokenRegistry.deployed();

  console.log("AgoraTokenRegistry deployed to", tokenRegistry.address);
  ////////

  ////////
  const AddressRegistry = await ethers.getContractFactory(
    "AgoraAddressRegistry"
  );
  const addressRegistry = await AddressRegistry.deploy();

  await addressRegistry.deployed();

  console.log("AgoraAddressRegistry deployed to", addressRegistry.address);
  const AGORA_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  ////////
  const PriceFeed = await ethers.getContractFactory("AgoraPriceFeed");
  const WRAPPED_ETH =
    network.name === "mainnet" ? WRAPPED_ETH_MAINNET : WRAPPED_ETH_TESTNET;
  const priceFeed = await PriceFeed.deploy(AGORA_ADDRESS_REGISTRY, WRAPPED_ETH);

  await priceFeed.deployed();

  console.log("AgoraPriceFeed deployed to", priceFeed.address);
  ////////

  ////////
  const ArtTradable = await ethers.getContractFactory("AgoraArtTradable");
  const artTradable = await ArtTradable.deploy(
    "AgoraArt",
    "AART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradable.deployed();
  console.log("AgoraArtTradable deployed to:", artTradable.address);

  const ArtTradablePrivate = await ethers.getContractFactory(
    "AgoraArtTradablePrivate"
  );
  const artTradablePrivate = await ArtTradablePrivate.deploy(
    "AgoraArt",
    "AART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS
  );
  await artTradablePrivate.deployed();
  console.log(
    "AgoraArtTradablePrivate deployed to:",
    artTradablePrivate.address
  );
  ////////

  ////////
  const ArtFactory = await ethers.getContractFactory("AgoraArtFactory");
  const artFactory = await ArtFactory.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactory.deployed();
  console.log("AgoraArtFactory deployed to:", artFactory.address);

  const ArtFactoryPrivate = await ethers.getContractFactory(
    "AgoraArtFactoryPrivate"
  );
  const artFactoryPrivate = await ArtFactoryPrivate.deploy(
    MARKETPLACE_PROXY_ADDRESS,
    BUNDLE_MARKETPLACE_PROXY_ADDRESS,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "25000000000000000000"
  );
  await artFactoryPrivate.deployed();
  console.log("AgoraArtFactoryPrivate deployed to:", artFactoryPrivate.address);
  ////////

  await marketplaceImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);

  await auctionImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);

  await addressRegistry.updateAgoraNFT(agoraNFT.address);
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
