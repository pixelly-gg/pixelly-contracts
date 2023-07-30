const {
  TREASURY_ADDRESS,
  PLATFORM_FEE,
  PROXY_ADMIN,
} = require("./constants");

async function main() {
  const Marketplace = await ethers.getContractFactory("TenartBundleMarketplace");
  const marketplaceImpl = await Marketplace.deploy();
  await marketplaceImpl.deployed();
  console.log("TenartBundleMarketplace deployed to:", marketplaceImpl.address);

  const AdminUpgradeabilityProxyFactory = await ethers.getContractFactory(
    "AdminUpgradeabilityProxy"
  );


  const marketplaceProxy = await AdminUpgradeabilityProxyFactory.deploy(
    marketplaceImpl.address,
    PROXY_ADMIN,
    []
  );


  await marketplaceProxy.deployed();
  console.log(
    "Bundle Marketplace Proxy deployed at ",
    marketplaceProxy.address
  );

  const marketplace = await ethers.getContractAt(
    "TenartBundleMarketplace",
    marketplaceProxy.address
  );
  await marketplace.initialize(TREASURY_ADDRESS, PLATFORM_FEE);
  console.log("Bundle Marketplace Proxy initialized");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
