const { WRAPPED_ETH_TESTNET } = require("../constants");

async function main(network) {
  console.log("network: ", network.name);
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deployer's address: `, deployerAddress);
  const PIXELLY_ADDRESS_REGISTRY = "0xB0660C7BcbC645549F8f52C6B3aE3B2D22f35fDd";

  const {
    TREASURY_ADDRESS,
    PLATFORM_FEE,
    WRAPPED_ETH_MAINNET,
    WRAPPED_ETH_TESTNET,
  } = require("../constants");

  const tokenRegistry = await (
    await ethers.getContractFactory("PixellyTokenRegistry")
  ).attach("0x9B415beb6e7D669431737Dc4E7C9bCc760CA01C3");

  const marketplaceImpl = await (
    await ethers.getContractFactory("PixellyMarketplace")
  ).attach("0x2d42C870AD85D4318887aff39b642C33E9e332c7");

  const auctionImpl = await (
    await ethers.getContractFactory("PixellyAuction")
  ).attach("0xF0E1Be2656e0d0DaC726f4677d42D4Bd15773A3d");

  const royaltiesImpl = await (
    await ethers.getContractFactory("PixellyRoyaltyRegistry")
  ).attach("0x88869D56F0E6BB5C8F89a97390D71E4C413030eD");

  console.log(
    await tokenRegistry.enabled("0xdf032bc4b9dc2782bb09352007d4c57b75160b15")
  );

  console.log(
    await marketplaceImpl.listings(
      "0xe2Bde7287870Ec0C018a3A42158B330020370E34",
      "5",
      "0xfa69874801cf5e0729309Ae27eeA826294a0909c"
    )
  );

  // await marketplaceImpl.buyItem(
  //   "0xe2Bde7287870Ec0C018a3A42158B330020370E34",
  //   "5",
  //   "0xdf032bc4b9dc2782bb09352007d4c57b75160b15",
  //   "0xfa69874801cf5e0729309Ae27eeA826294a0909c"
  // );
  // console.log("Item bought");

  // await auctionImpl.createAuction(
  //   "0xe2Bde7287870Ec0C018a3A42158B330020370E34",
  //   "6",
  //   "0xdf032bc4b9dc2782bb09352007d4c57b75160b15",
  //   "10000000000000000",
  //   "1642157303",
  //   "false",
  //   "1642243703"
  // );
  // console.log("Auction created");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(network)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
