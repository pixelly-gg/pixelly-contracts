async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  ////////
  const auctionV2 = await ethers.getContractFactory("AgoraAuction");
  console.log("Upgrading Auctions...");
  await upgrades.upgradeProxy(
    "0xA84bf88521479A7c4565a0fa2Ca48c7Ce8Ffb404",
    auctionV2
  );
  console.log("Actions upgraded");
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
