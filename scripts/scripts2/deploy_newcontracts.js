async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  const { TREASURY_ADDRESS } = require("../constants");

  ////////////
  const RoyaltiesRegistry = await ethers.getContractFactory(
    "TenartRoyaltyRegistry"
  );
  const royaltiesRegistry = await RoyaltiesRegistry.deploy();

  await royaltiesRegistry.deployed();
  console.log("TenartRoyaltyRegistry deployed at", royaltiesRegistry.address);
  ///////////

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
  const marketplaceV2 = await ethers.getContractFactory("TenartMarketplace");
  console.log("Upgrading Marketplace...");
  await upgrades.upgradeProxy(
    "0xa974469C8e1b339e54Ffc42e9e128b929707A10A",
    marketplaceV2
  );
  console.log("Marketplace upgraded");
  ////////

  ////////
  const auctionV2 = await ethers.getContractFactory("TenartAuction");
  console.log("Upgrading Auctions...");
  await upgrades.upgradeProxy(
    "0xA84bf88521479A7c4565a0fa2Ca48c7Ce8Ffb404",
    auctionV2
  );
  console.log("Actions upgraded");
  ////////

  ////////////
  const TenartNFT = await ethers.getContractFactory("TenartNFT");
  const tenartNFT = await TenartNFT.deploy(
    TREASURY_ADDRESS,
    "2000000000000000000"
  );

  await tenartNFT.deployed();
  console.log("TenartNFT deployed at", tenartNFT.address);
  ///////////

  ////////

  await marketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(
    "0xe9391A3253625d0a06973e4Be11D9932ba4F788D"
  );

  await auctionImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);

  await addressRegistry.updateTenartNFT(tenartNFT.address);
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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
