async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log("Deploying nft with address:", deployerAddress);

  const royaltiesReg = await (
    await ethers.getContractFactory("PixellyRoyaltyRegistry")
  ).attach("0x59FF41d6ccD50C3C89773cc03Ae20E4634e556Bf");

  await royaltiesReg.setDefaultRoyalty(
    "0x939b90c529f0e3a2c187e1b190ca966a95881fde",
    "0x3f38c4662ec52140cda3825b55a1dd7a1a3a6f8c",
    "500"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
