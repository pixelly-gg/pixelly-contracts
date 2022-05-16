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
    await ethers.getContractFactory("AgoraMarketplace")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D"); //Replace by the right address, deployed before

  const auctionImpl = await (
    await ethers.getContractFactory("AgoraAuction")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D"); //Replace by the right address, deployed before

  const bundleMarketplaceImpl = await (
    await ethers.getContractFactory("AgoraBundleMarketplace")
  ).attach("0xe9391A3253625d0a06973e4Be11D9932ba4F788D");

  ////////////
  const RoyaltiesRegistry = await ethers.getContractFactory(
    "AgoraRoyaltyRegistry"
  );
  const royaltiesRegistry = await RoyaltiesRegistry.deploy();

  await royaltiesRegistry.deployed();
  console.log("AgoraRoyaltyRegistry deployed at", royaltiesRegistry.address);
  ///////////

  ////////
  const AddressRegistry = await ethers.getContractFactory(
    "AgoraAddressRegistry"
  );
  const addressRegistry = await AddressRegistry.deploy();

  await addressRegistry.deployed();

  console.log("AgoraAddressRegistry deployed to", addressRegistry.address);
  const AGORA_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  ////////////
  const AgoraNFT = await ethers.getContractFactory("AgoraNFT");
  const agoraNFT = await AgoraNFT.deploy(
    TREASURY_ADDRESS,
    "2000000000000000000"
  );

  await agoraNFT.deployed();
  console.log("AgoraNFT deployed at", agoraNFT.address);
  ///////////

  ////////

  await marketplaceImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);
  await auctionImpl.updateAddressRegistry(AGORA_ADDRESS_REGISTRY);

  await addressRegistry.updateAgoraNFT(agoraNFT.address);
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
