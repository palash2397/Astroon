
const { ethers, upgrades } = require("hardhat");



const proxy1 = "0xA7a399862EBc5aa01b433da072c23D668aBEa92A";
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());
  const contract = await ethers.getContractFactory("ASTNftSale");

  const Ast = await upgrades.upgradeProxy(proxy1, contract);
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