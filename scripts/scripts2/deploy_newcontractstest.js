async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  const { TREASURY_ADDRESS } = require("../constants");

  const bundleMarketplaceImpl = await (
    await ethers.getContractFactory("TenartBundleMarketplace")
  ).attach("0x228b3DCa55Ce35CEC39a9c643FdfDa47Bec16473");

  ////////////
  // const RoyaltiesRegistry = await ethers.getContractFactory(
  //   "TenartRoyaltyRegistry"
  // );
  // const royaltiesRegistry = await RoyaltiesRegistry.deploy();

  // await royaltiesRegistry.deployed();
  // console.log("TenartRoyaltyRegistry deployed at", royaltiesRegistry.address);
  ///////////

  ////////
  // const AddressRegistry = await ethers.getContractFactory(
  //   "TenartAddressRegistry"
  // );
  // const addressRegistry = await AddressRegistry.deploy();

  // await addressRegistry.deployed();

  // console.log("TenartAddressRegistry deployed to", addressRegistry.address);
  // const TENART_ADDRESS_REGISTRY = addressRegistry.address;
  ////////

  //////
  const marketplaceV2 = await ethers.getContractFactory("TenartMarketplace");
  console.log("Upgrading Marketplace...");
  await upgrades.upgradeProxy(
    "0x4436457F31954AcCACCA7188A13242A03E3d40Af",
    marketplaceV2
  );
  console.log("Marketplace upgraded");
  //////

  //////
  const auctionV2 = await ethers.getContractFactory("TenartAuction");
  console.log("Upgrading Auctions...");
  await upgrades.upgradeProxy(
    "0xF0E1Be2656e0d0DaC726f4677d42D4Bd15773A3d",
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

  await marketplaceV2.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  await bundleMarketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);

  await auctionV2.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  console.log("updated address registry");

  await addressRegistry.updateTenartNFT(tenartNFT.address);
  await addressRegistry.updateAuction(auctionV2.address);
  await addressRegistry.updateMarketplace(marketplaceV2.address);
  await addressRegistry.updateBundleMarketplace(bundleMarketplaceImpl.address);
  await addressRegistry.updateNFTFactory(
    "0x7bc2a340F80602ba3646EEdf9976b36AD0f457ef"
  );
  await addressRegistry.updateTokenRegistry(
    "0x9B415beb6e7D669431737Dc4E7C9bCc760CA01C3"
  );
  await addressRegistry.updatePriceFeed(
    "0x622DDa07B83e6C69F4DDD38c7EF53635bD777F74"
  );
  await addressRegistry.updateArtFactory(
    "0x41a5843dBDDcB49214D1Cff9790975261097EE0f"
  );
  console.log("updated on the address registry");
  await royaltiesRegistry.setDefaultRoyalty(
    "0xe2Bde7287870Ec0C018a3A42158B330020370E34",
    "0xfa69874801cf5e0729309Ae27eeA826294a0909c",
    "500"
  );
  console.log("added Royalties");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
