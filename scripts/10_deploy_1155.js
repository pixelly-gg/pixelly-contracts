const {
  TREASURY_ADDRESS,
  MARKETPLACE,
  BUNDLE_MARKETPLACE,
} = require("./constants");

async function main() {
  const ArtTradable = await ethers.getContractFactory("PixellyArtTradable");
  const nft = await ArtTradable.deploy(
    "PixellyArt",
    "AART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE,
    BUNDLE_MARKETPLACE
  );
  await nft.deployed();
  console.log("PixellyArtTradable deployed to:", nft.address);

  const ArtTradablePrivate = await ethers.getContractFactory(
    "PixellyArtTradablePrivate"
  );
  const nftPrivate = await ArtTradablePrivate.deploy(
    "PixellyArt",
    "TNART",
    "20000000000000000000",
    TREASURY_ADDRESS,
    MARKETPLACE,
    BUNDLE_MARKETPLACE
  );
  await nftPrivate.deployed();
  console.log("PixellyArtTradablePrivate deployed to:", nftPrivate.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
