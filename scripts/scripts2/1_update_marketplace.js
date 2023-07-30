async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  ////////
  const marketplaceV2 = await ethers.getContractFactory("TenartMarketplace");
  console.log("Upgrading Marketplace...");
  await upgrades.upgradeProxy(
    "0xa974469C8e1b339e54Ffc42e9e128b929707A10A",
    marketplaceV2
  );
  console.log("Marketplace upgraded");
  ////////
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
