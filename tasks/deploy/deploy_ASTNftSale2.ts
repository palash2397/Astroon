import hre from "hardhat";

const { ethers, upgrades } = require("hardhat");

const name = "Astroon";
const symbol = "ASTNFT";
const _baseUri = " ipfs://contracts.json";
const _notRevealedURI = "ipfs://notRevealed.json";
const _receiverAddress = "0xA9fAFe1D8B449D18Fed789728d28342dA2389e7C";
const _astTokenaddr = "0xcAB7E2499Df2e4E4d74AF83f6a0484E25E3F1C32";
const _RoyaltyAmt = 125000000000000;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const contract = await ethers.getContractFactory("ASTNftSale2");

  const sale = await upgrades.deployProxy(
    contract,
    [name, symbol, _baseUri, _notRevealedURI, _receiverAddress, _astTokenaddr, _RoyaltyAmt],
    { initializer: "initialize" },
  );

  await sale.deployed();

  console.log("Contract deployed to :", sale.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.info("check");
    console.error(error);
    process.exit(1);
  });
