require("dotenv").config();
const { MARKETPLACE, PIXELLY_ADDRESS_REGISTRY } = require("./constants");

async function main() {

  // // Testnet
  // const marketplaceProxy = await AdminUpgradeabilityProxyFactory.deploy(
  //   marketplaceImpl.address,
  //   proxyAdmin.address,
  //   []
  // );

  const marketplace = await ethers.getContractAt(
    "PixellyMarketplace",
    MARKETPLACE
  );
  await marketplace.updateAddressRegistry(PIXELLY_ADDRESS_REGISTRY);

  console.log("Address registry set");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
