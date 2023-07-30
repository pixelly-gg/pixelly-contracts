async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);
  const TENART_ADDRESS_REGISTRY = "0xB0660C7BcbC645549F8f52C6B3aE3B2D22f35fDd";

  const { WRAPPED_ETH_MAINNET } = require("../constants");

  const marketplaceImpl = await (
    await ethers.getContractFactory("TenartMarketplace")
  ).attach("0x4Ac3c9Ff510f6D5Dd32FCea929785aE7924A8C26");

  const bundleMarketplaceImpl = await (
    await ethers.getContractFactory("TenartBundleMarketplace")
  ).attach("0x91014F399E4bd35BDCB340466baBF1a0034Fa1DF");

  const auctionImpl = await (
    await ethers.getContractFactory("TenartAuction")
  ).attach("0xFb7190641C5ab98585D9259Ef52Db881066179Ee");

  const addressRegistry = await (
    await ethers.getContractFactory("TenartAddressRegistry")
  ).attach("0xB0660C7BcbC645549F8f52C6B3aE3B2D22f35fDd");

  const tokenRegistry = await (
    await ethers.getContractFactory("TenartTokenRegistry")
  ).attach("0xEC082041260Cc6880A120426f167B228E4955528");

  await marketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  console.log("Marketplace Address Registry updated");
  await bundleMarketplaceImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  console.log("MarketplaceBundle Address Registry updated");
  await auctionImpl.updateAddressRegistry(TENART_ADDRESS_REGISTRY);
  console.log("Auction Address Registry updated");
  await addressRegistry.updateTenartNFT(
    "0x491829466dc1fD03dCFC57EE22933814a5804C7a"
  );
  console.log("Address Registry TenartNFT");
  await addressRegistry.updateAuction(auctionImpl.address);
  console.log("Address Registry Auction");
  await addressRegistry.updateMarketplace(marketplaceImpl.address);
  console.log("Address Registry Marketplace");
  await addressRegistry.updateBundleMarketplace(bundleMarketplaceImpl.address);
  console.log("Address Registry Bundle");
  await addressRegistry.updateNFTFactory(
    "0xA7E216B65696a40238A6aCC1afce06eAc81f94b3"
  );
  console.log("Address Registry factory");
  await addressRegistry.updateTokenRegistry(
    "0xEC082041260Cc6880A120426f167B228E4955528"
  );
  console.log("Address Registry tokenreg");
  await addressRegistry.updatePriceFeed(
    "0x9BFaaE53C58b9128ad3e3050eE494de465888eEc"
  );
  console.log("Address Registry PriceFeed");
  await addressRegistry.updateArtFactory(
    "0x50Ee45fdA98ab9674a2C97C4ec070Af4d1f3F9Af"
  );
  console.log("Address Registry ArtFactory");

  await tokenRegistry.add(WRAPPED_ETH_MAINNET);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
