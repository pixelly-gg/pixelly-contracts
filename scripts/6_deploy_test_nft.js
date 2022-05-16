const {
  TREASURY_ADDRESS,
  AUCTION,
  MARKETPLACE,
  BUNDLE_MARKETPLACE,
} = require("./constants");

async function main() {
  const NFTTradable = await ethers.getContractFactory("AgoraNFTTradable");
  const nft = await NFTTradable.deploy(
    "AgoraNFT",
    "ANFT",
    AUCTION,
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nft.deployed();
  console.log("AgoraNFTTradable deployed to:", nft.address);

  const NFTTradablePrivate = await ethers.getContractFactory(
    "AgoraNFTTradablePrivate"
  );
  const nftPrivate = await NFTTradablePrivate.deploy(
    "IAgoraNFT",
    "IANFT",
    AUCTION,
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "10000000000000000000",
    TREASURY_ADDRESS
  );
  await nftPrivate.deployed();
  console.log("AgoraNFTTradablePrivate deployed to:", nftPrivate.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
