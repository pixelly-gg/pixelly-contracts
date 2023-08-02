async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);
  const PIXELLY_ADDRESS_REGISTRY = "0x55b82Af8E85A17D62F140f01e9b6c457519BD484";

  const { WRAPPED_ETH_MAINNET } = require("../constants");

  const art = await (await ethers.getContractFactory("PixellyNFTFactory")).attach(
    "0xBBefe6432A7A772DB0F282361E3506764d8b8212"
  );

  const artPrivate = await (
    await ethers.getContractFactory("PixellyNFTFactoryPrivate")
  ).attach("0x9FE47b52d17C574EDF4B7F5Aab558287e71bd6a1");

  await art.updateMintFee("2000000000000000000");
  console.log("Platform Fees Tradable");
  await artPrivate.updateMintFee("2000000000000000000");
  console.log("Platform Fees Tradable Private");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
