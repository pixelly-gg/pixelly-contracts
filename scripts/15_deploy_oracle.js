const { USDC, TENDIES_FACTORY } = require("./constants");
  
  async function main() {
    const oracleFactory = await ethers.getContractFactory("Oracle");
    const oracle = await oracleFactory.deploy(TENDIES_FACTORY, USDC);
    await oracle.deployed();
    console.log("Price Oracle", oracle.address);
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
  });