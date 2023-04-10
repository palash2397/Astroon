
const { ethers, upgrades } = require("hardhat");
const receiver = "0xb178512aA2C4D0c3C43a12c7b7C2d1465fe298A5";

const add = "0xcAB7E2499Df2e4E4d74AF83f6a0484E25E3F1C32"; //ast token address

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const contract = await ethers.getContractFactory("ASTNftSale");

  const Ast = await upgrades.deployProxy(contract, ["ASTRoon", "ASTNft", "https://ipfs.io/ipfs/QmSRRqEcDZK3azRebTngLuMoReoe7VMZWF1BeV9YNmXdTv/", add, ".json", 10, "1500000000000000000000", receiver, 500 ], { initializer: "initialize" });

  
  await Ast.deployed();
  console.log("Contract deployed to :", Ast.address);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.info("check");
    console.error(error);
    process.exit(1);
  });