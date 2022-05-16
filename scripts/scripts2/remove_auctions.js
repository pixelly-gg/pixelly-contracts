async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  const feeSharing = await (
    await ethers.getContractFactory("FeeSharingSystem")
  ).attach("0x2bDDBA3F7DD5Fd18da89CD7eD5BaA1da37FD4eE0");

  const tokenSplitter = await (
    await ethers.getContractFactory("TokenSplitter")
  ).attach("0x5A34FD93f9634dB8930888f0d25939215B757A32");

  const tradingRewardsDistributor = await (
    await ethers.getContractFactory("TradingRewardsDistributor")
  ).attach("0x3A0d3b7FAAb7fc4bAADf9805992cE536099B98E8");

  await feeSharing.updateRewards("3600000000000000000000", "14400");

  // console.log("Fee Sharing");

  await tokenSplitter.releaseTokens(
    "0xB990684E11064528fE8BE45D0e02e1ef6DD19865"
  );
  console.log("Release Token");

  // await tradingRewardsDistributor.updateTradingRewards(
  //   "0xc0b8c0a68ad256897a92357255de6d9c48fac6e339038172b949018cedbb735d",
  //   "100000000000000000000000"
  // );

  console.log("Trading Rewards");

  console.log("finished");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
