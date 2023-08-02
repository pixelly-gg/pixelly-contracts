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

  const marketplaceImpl = await (
    await ethers.getContractFactory("PixellyMarketplace")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D"); //Replace by the right address, deployed before

  const auctionImpl = await (
    await ethers.getContractFactory("PixellyAuction")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D"); //Replace by the right address, deployed before

  const bundleMarketplaceImpl = await (
    await ethers.getContractFactory("PixellyBundleMarketplace")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D");

  ////////////
  const RoyaltiesRegistry = await ethers.getContractFactory(
    "PixellyRoyaltyRegistry"
  );
  const royaltiesRegistry = await RoyaltiesRegistry.deploy();

  await royaltiesRegistry.deployed();
  console.log("PixellyRoyaltyRegistry deployed at", royaltiesRegistry.address);
  ///////////

  ////////
  const AddressRegistry = await ethers.getContractFactory(
    "PixellyAddressRegistry"
  );
  const addressRegistry = await AddressRegistry.deploy();

  await addressRegistry.deployed();

  console.log("PixellyAddressRegistry deployed to", addressRegistry.address);
  const TENART_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  ////////////
  const PixellyNFT = await ethers.getContractFactory("PixellyNFT");
  const tenartNFT = await PixellyNFT.deploy(
    TREASURY_ADDRESS,
    "2000000000000000000"
  );

  await tenartNFT.deployed();
  console.log("PixellyNFT deployed at", tenartNFT.address);
  ///////////

  ////////

  await marketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  await auctionImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);

  await addressRegistry.updatePixellyNFT(tenartNFT.address);
  await addressRegistry.updateAuction(auctionImpl.address);
  await addressRegistry.updateMarketplace(marketplaceImpl.address);
  await addressRegistry.updateBundleMarketplace(
    "0xe9391A3253625d0a06973e4Be11D9932ba4F788D"
  );
  await addressRegistry.updateNFTFactory(
    "0xBBefe6432A7A772DB0F282361E3506764d8b8212"
  );
  await addressRegistry.updateTokenRegistry(
    "0xd574671938989EF54F9bC50D0c2c4B4A98a98E57"
  );
  await addressRegistry.updatePriceFeed(
    "0x9BFaaE53C58b9128ad3e3050eE494de465888eEc"
  );
  await addressRegistry.updateArtFactory(
    "0x3aD833eb7075B94517A969adff2B3e638c089B90"
  );
  await addressRegistry.updateRoyaltyRegistry(royaltiesRegistry.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
