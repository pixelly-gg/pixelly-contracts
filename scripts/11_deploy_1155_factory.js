const {
  TREASURY_ADDRESS,
  MARKETPLACE,
  BUNDLE_MARKETPLACE,
} = require("./constants");

async function main() {
  const Factory = await ethers.getContractFactory("PixellyArtFactory");
  const factory = await Factory.deploy(
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "10000000000000000000"
  );
  await factory.deployed();
  console.log("PixellyArtFactory deployed to:", factory.address);

  const PrivateFactory = await ethers.getContractFactory(
    "PixellyArtFactoryPrivate"
  );
  const privateFactory = await PrivateFactory.deploy(
    MARKETPLACE,
    BUNDLE_MARKETPLACE,
    "20000000000000000000",
    TREASURY_ADDRESS,
    "10000000000000000000"
  );
  await privateFactory.deployed();
  console.log("PixellyArtFactoryPrivate deployed to:", privateFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
