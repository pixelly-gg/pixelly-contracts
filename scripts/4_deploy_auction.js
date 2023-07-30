const {
  TREASURY_ADDRESS,
  PROXY_ADMIN,
} = require("./constants");

async function main() {
  const Auction = await ethers.getContractFactory("TenartAuction");
  const auctionImpl = await Auction.deploy();
  await auctionImpl.deployed();
  console.log("TenartAuction deployed to:", auctionImpl.address);

  const AdminUpgradeabilityProxyFactory = await ethers.getContractFactory(
    'AdminUpgradeabilityProxy'
  );


  const auctionProxy = await AdminUpgradeabilityProxyFactory.deploy(
    auctionImpl.address,
    PROXY_ADMIN,
    []
  );


  await auctionProxy.deployed();
  console.log('Auction Proxy deployed at ', auctionProxy.address);

  const auction = await ethers.getContractAt(
    'TenartAuction',
    auctionProxy.address
  );

  const min_bid_increment = 1

  await auction.initialize(TREASURY_ADDRESS, min_bid_increment);
  console.log('Auction Proxy initialized');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
