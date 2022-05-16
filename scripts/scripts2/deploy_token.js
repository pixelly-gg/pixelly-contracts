// to deploy locally
// run: npx hardhat node on a terminal
async function main(network) {
  console.log("network: ", network.name);

  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);

  ////////
  //   const TradingRewardsDistributor = await ethers.getContractFactory(
  //     "TradingRewardsDistributor"
  //   );
  //   const tradingRewardsDistributor = await TradingRewardsDistributor.deploy(
  //     "0x383627CaeC2CE3b36793c34B576B2e97BEDA0466"
  //   );
  //   await tradingRewardsDistributor.deployed();
  //   const TRADING_CONTRACT = tradingRewardsDistributor.address;

  //   console.log(
  //     "TradingRewardsDistributor deployed to:",
  //     tradingRewardsDistributor.address
  //   );

  //////////

  ////////
  //   const VestingContract = await ethers.getContractFactory(
  //     "VestingContractWithFeeSharing"
  //   );
  //   const vestingContract = await VestingContract.deploy(
  //     "864000",
  //     "1587200",
  //     "8",
  //     "1250000000000000000000000",
  //     "0x383627CaeC2CE3b36793c34B576B2e97BEDA0466"
  //   );
  //   await vestingContract.deployed();
  //   const VESTING_CONTRACT = vestingContract.address;

  //   console.log("VestingContract deployed to:", vestingContract.address);
  //////////

  ////////
  //   const TokenSplitter = await ethers.getContractFactory("TokenSplitter");
  //   const tokenSplitter = await TokenSplitter.deploy(
  //     [VESTING_CONTRACT, TRADING_CONTRACT],
  //     ["3200", "4410"],
  //     "0x383627CaeC2CE3b36793c34B576B2e97BEDA0466"
  //   );
  //   await tokenSplitter.deployed();
  //   const TOKEN_SPLITTER = tokenSplitter.address;

  //   console.log("tokenSplitter deployed to:", tokenSplitter.address);
  //////////

  const TOKEN_SPLITTER = "0x5A34FD93f9634dB8930888f0d25939215B757A32";

  ////////
  const TokenDistributor = await ethers.getContractFactory("TokenDistributor");
  const tokenDistributor = await TokenDistributor.deploy(
    "0x383627CaeC2CE3b36793c34B576B2e97BEDA0466",
    TOKEN_SPLITTER,
    "1587200",
    [
      "6000000000000000000",
      "4400000000000000000",
      "1700000000000000000",
      "910000000000000000",
    ],
    [
      "16753500000000000000",
      "12753500000000000000",
      "6753500000000000000",
      "4903500000000000000",
    ],
    ["432000", "1296000", "3456000", "5198400"],
    "4"
  );
  await tokenDistributor.deployed();
  const TOKEN_DISTRIBUTOR = tokenDistributor.address;
  console.log("TokenDistributor deployed to:", tokenDistributor.address);
  //////////

  ////////
  const FeeSharingSystem = await ethers.getContractFactory("FeeSharingSystem");
  const feeSharingSystem = await FeeSharingSystem.deploy(
    "0x383627CaeC2CE3b36793c34B576B2e97BEDA0466",
    "0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23",
    TOKEN_DISTRIBUTOR
  );
  await feeSharingSystem.deployed();
  console.log("FeeSharingSystem deployed to:", feeSharingSystem.address);
  //////////
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
