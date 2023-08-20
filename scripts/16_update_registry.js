// to deploy locally

const { PIXELLY_TOKEN_REGISTRY, PIXELLY_ART_FACTORY } = require("./constants");

// run: npx hardhat node on a terminal
async function main(network) {
    console.log("network: ", network.name);
  
    const [deployer] = await ethers.getSigners();
    const deployerAddress = await deployer.getAddress();
    console.log(`Deployer's address: `, deployerAddress);
  
    const {
        WRAPPED_TENET,
        ORACLE,
        PIXELLY_ADDRESS_REGISTRY,
        AUCTION,
        MARKETPLACE,
        BUNDLE_MARKETPLACE,
        PIXELLY_PRICE_FEED,
        PIXELLYNFT,
        PIXELLY_NFT_FACTORY,
        PIXELLY_TOKEN_REGISTRY,
        PIXELLY_ART_FACTORY,
    } = require("./constants");
  
    const addressRegistry = await ethers.getContractAt("PixellyAddressRegistry", PIXELLY_ADDRESS_REGISTRY);
    const priceFeed = await ethers.getContractAt("PixellyPriceFeed", PIXELLY_PRICE_FEED);
    const tokenRegistry = await ethers.getContractAt("PixellyTokenRegistry", PIXELLY_TOKEN_REGISTRY);

    await addressRegistry.updatePixelly(PIXELLYNFT);
    await addressRegistry.updateAuction(AUCTION);
    await addressRegistry.updateMarketplace(MARKETPLACE);
    await addressRegistry.updateBundleMarketplace(BUNDLE_MARKETPLACE);
    await addressRegistry.updateNFTFactory(PIXELLY_NFT_FACTORY);
    await addressRegistry.updateTokenRegistry(PIXELLY_TOKEN_REGISTRY);
    await addressRegistry.updatePriceFeed(PIXELLY_PRICE_FEED);
    await addressRegistry.updateArtFactory(PIXELLY_ART_FACTORY);

    await tokenRegistry.add(WRAPPED_TENET);
  
    await priceFeed.registerOracle(WRAPPED_TENET, ORACLE);
  }
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main(network)
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  