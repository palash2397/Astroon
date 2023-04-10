
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const nftcontract = await ethers.getContractFactory("MyToken");
  const ERCcontract = await nftcontract.deploy()
  await ERCcontract.deployed();
  console.log("Contract deployed to :", ERCcontract.address);

  
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.info("check");
    console.error(error);
    process.exit(1);
  });