async function main() {
    const [deployer] = await ethers.getSigners();
    const deployerAddress = await deployer.getAddress();
    console.log("Deploying WTENET with address:", deployerAddress);
  
    const WTENET = await ethers.getContractFactory("WTENET");
    const contract = await WTENET.deploy();
  
    await contract.deployed();
  
    console.log("WTENET deployed at", contract.address);
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });