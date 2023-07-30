const {
  TREASURY_ADDRESS,
  AUCTION,
  MARKETPLACE,
  BUNDLE_MARKETPLACE,
} = require("./constants");

async function main() {
  const NFTTradable = await ethers.getContractFactory("TenartNFTTradable");
  const nft = await NFTTradable.deploy(
    "TenartNFT",
    "TNFT",
    AUCTION,
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nft.deployed();
  console.log("TenartNFTTradable deployed to:", nft.address);

  const NFTTradablePrivate = await ethers.getContractFactory(
    "TenartNFTTradablePrivate"
  );
  const nftPrivate = await NFTTradablePrivate.deploy(
    "ITenartNFT",
    "ITNFT",
    AUCTION,
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nftPrivate.deployed();
  console.log("TenartNFTTradablePrivate deployed to:", nftPrivate.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
