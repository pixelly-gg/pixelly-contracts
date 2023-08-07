const {
  PIXELLY_ADDRESS_REGISTRY,
  WRAPPED_TENET
} = require("./constants");

async function main() {
  const Contract = await ethers.getContractFactory("PixellyPriceFeed");
  const contract = await Contract.deploy(
    PIXELLY_ADDRESS_REGISTRY,
    WRAPPED_TENET
  );

  await contract.deployed();

  console.log("PixellyPriceFeed deployed to", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
