const {
  TENART_ADDRESS_REGISTRY,
  WRAPPED_TENET_TESTNET
} = require("./constants");

async function main() {
  const Contract = await ethers.getContractFactory("TenartPriceFeed");
  const contract = await Contract.deploy(
    TENART_ADDRESS_REGISTRY,
    WRAPPED_TENET_TESTNET
  );

  await contract.deployed();

  console.log("TenartPriceFeed deployed to", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
