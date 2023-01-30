import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { doesNotMatch } from "assert";
import { expect } from "chai";

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");

//import { ASTILO } from "../typechain";

import { ethers } from 'hardhat'
import { upgrades } from 'hardhat'
const truffleAssert = require('truffle-assertions');
const receiver = "0x4F02C3102A9D2e1cC0cC97c7fE2429B9B6F5965D";


describe("Unit Tests", function () {

    let token:any, astNft:any, astReward:any, admin:SignerWithAddress, user:SignerWithAddress

    const _rate = (780000000000000).toString(); //.00078 ether
    const _cap = ("7800000000000000000").toString();

    const _ddays = (2).toString();
    const _threshold = ("10000000000000000000").toString(); //10
    const _cliff = 0;
    const _vesting = (5).toString();
    const _minBound = ("5000000000000000000").toString();
  
    beforeEach(async function () {
        const signers: SignerWithAddress[] = await ethers.getSigners();
        admin = signers[0];
        user = signers[1];
    
        const astToken = await ethers.getContractFactory("ASTToken");
        token = await astToken.deploy();
        await token.deployed();
        
        const nft = await ethers.getContractFactory("ASTNftSale");
        astNft = await upgrades.deployProxy(nft, ["ASTNFT", "AstNft", "http://ipfs.io/ipfs/", token.address, ".json", 10, "1500000000000000000000", receiver, 1], {
        initializer: "initialize",
        });
        await astNft.deployed();
       
        const reward = await ethers.getContractFactory("ASTTokenRewards");
        
        astReward = await upgrades.deployProxy(reward, [astNft.address, token.address], {
        initializer: "initialize",
        });
        await astReward.deployed();
      
        await astNft.setRewardContract(astReward.address);
        
        const blockNumber = await ethers.provider.getBlockNumber();
        const { timestamp } = await ethers.provider.getBlock(blockNumber);

        const tx = await astNft.startPreSale((400*10**18).toString(), (0.1*10**18).toString(), 2400, timestamp, timestamp+(30*24*60*60));
        var x = parseInt((await tx.wait()).logs[0].data);

        await astNft.setTireMap(2, "1500000000000000000000",  "3000000000000000000000");
        await astNft.connect(admin).setTireMap(4, "3000000000000000000000","4500000000000000000000");
        await astNft.connect(admin).setTireMap(6, "4500000000000000000000","6000000000000000000000");
        await astNft.connect(admin).setTireMap(8, "6000000000000000000000","7500000000000000000000");
    });

    describe("ASTNFT", () => {
        it("PreSale buy one by one", async  ()=> {
            
           await token.connect(user).approve(astNft.address, "7000000000000000000000")
           await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
           await token.transfer(user.address, "8000000000000000000000");
          
           
           var tx = await astNft.connect(user).buyPresale(1,{ value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');

            // await token.transfer(user.address, (800*10**18).toString());
            // var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            // var txn = await tx.wait();

            // await ethers.provider.send("evm_increaseTime", [365*24*60*60])
            // await ethers.provider.send("evm_mine")
            // var tx = await astReward.getRewardsCalc(0, 1, user.address)
            // console.log("reward", parseInt(tx))
            // await token.connect(admin).transfer( astReward.address, ("1000000000000000000000".toString()));
            // await astReward.connect(user).claim();
            // await ethers.provider.send("evm_increaseTime", [((365*2) + 300)*24*60*60])
            // await ethers.provider.send("evm_mine")
            // tx = await astReward.getRewardsCalc(0, 1, user.address)
            // console.log("reward", parseInt(tx))
           
          
        })
        
        it("PreSale buy two-two", async function () {
              
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
         
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
            
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();


            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (2*(0.1*10**18)).toString()}), 'buying Limit exceeded');
           
        });
        

        it("PreSale buy three-three", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(3,{ value: (3*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(3,{value: (3*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(3,{value: (3*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "1400000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (2*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });


        it("PreSale buy four-four", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{value: (4*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy five-five", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(5,{ value: (5*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(5,{value: (5*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
          
            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });


        it("PreSale buy six-six", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(6,{ value: (6*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(3,{value: (3*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
          
            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy seven-seven", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(7,{ value: (7*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });


        it("PreSale buy Eight-Eight", async function () {
            await token.connect(user).approve(astNft.address, "7000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "800000000000000000000")
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(8,{ value: (8*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await token.transfer(user.address, "8000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
          
            await token.transfer(user.address, "8000000000000000000000");
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy Only-two", async function () {
            await token.connect(user).approve(astNft.address, "2500000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "3000000000000000000000")
            await token.transfer(user.address, "1500000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
         
            await token.transfer(user.address, "1400000000000000000000");
         
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy Only-four", async function () {
            await token.connect(user).approve(astNft.address, "5000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "600000000000000000000")
            await token.transfer(user.address, "4400000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });
        it("PreSale buy Only-six", async function () {
            await token.connect(user).approve(astNft.address, "5000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "600000000000000000000")
            await token.transfer(user.address, "5000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy Only-eight", async function () {
            await token.connect(user).approve(astNft.address, "5000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address, "750000000000000000000")
            await token.transfer(user.address, "7000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*( 0.1*10**18)).toString()});
            var txn = await tx.wait();
            
            var tx = await astNft.connect(user).buyPresale(1,{ value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            var tx = await astNft.connect(user).buyPresale(1,{ value: (1*( 0.1*10**18)).toString()});
            var txn = await tx.wait();

            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(0.1*10**18)).toString()}), 'buying Limit exceeded');
        });
        it("PreSale buy In between token removal from balance eight-eight", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"7000000000000000000000")
            await token.transfer(user.address, "7000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(8,{ value: (8*(0.1*10**18)).toString()});
            var txn = await tx.wait();
           
      

            await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
        });
        it("PreSale buy In between token removal from balance seven-seven", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"7000000000000000000000")
            await token.transfer(user.address, "7000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(7,{ value: (7*(0.1*10**18)).toString()});
            var txn = await tx.wait();
           
      

            await truffleAssert.reverts(astNft.connect(user).buyPresale(3,{value: (3*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

      
        it("PreSale buy In between token removal from balance six-six", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"4500000000000000000000")
            await token.transfer(user.address, "5000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*(0.1*10**18)).toString()});
            var txn = await tx.wait();
           
            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*(0.1*10**18)).toString()});
            var txn = await tx.wait();

            await truffleAssert.reverts(astNft.connect(user).buyPresale(3,{value: (3*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
        });
        it("PreSale buy In between token removal from balance five-five", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"6000000000000000000000")
            await token.transfer(user.address, "5000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(5,{ value: (5*(0.1*10**18)).toString()});
            var txn = await tx.wait();

            await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
         
        
        });

        it("PreSale buy In between token removal from balance four-four", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"6000000000000000000000")
            await token.transfer(user.address, "4000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(4,{ value: (4*(0.1*10**18)).toString()});
            var txn = await tx.wait();

            await truffleAssert.reverts(astNft.connect(user).buyPresale(4,{value: (4*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
         
        
        });

        it("PreSale buy In between token removal from balance three-three", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"4500000000000000000000")
            await token.transfer(user.address, "4000000000000000000000");
            var tx = await astNft.connect(user).buyPresale(3,{ value: (3*(0.1*10**18)).toString()});
            var txn = await tx.wait();
        
            await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
        });

        it("PreSale buy In between token removal from balance two-two", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"4500000000000000000000")
            await token.transfer(user.address, "2900000000000000000000");
            var tx = await astNft.connect(user).buyPresale(2,{ value: (2*(  0.1*10**18)).toString()});
            var txn = await tx.wait();
            
         
            await truffleAssert.reverts(astNft.connect(user).buyPresale(3,{value: (3*(  0.1*10**18)).toString()}), 'buying Limit exceeded'); 
        });

       it("PreSale buy In between token removal from balance one by one", async function () {
            await token.approve(astNft.address, "3000000000000000000000")
            await token.connect(user).increaseAllowance(astNft.address,"4500000000000000000000")
            await token.transfer(user.address, "2900000000000000000000");
            var tx = await astNft.connect(user).buyPresale(1,{ value: (1*( 0.1*10**18)).toString()});
          
            var txn = await tx.wait();
           
            await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (2*( 0.1*10**18)).toString()}), 'buying Limit exceeded');
            
        });

        
        it("PublicSale and privatesale validate or not", async function () {
            await ethers.provider.send("evm_increaseTime", [30*24*60*60])
            expect(astNft.connect(user).buyPresale(1,{value: (1*(  0.1*10**18)).toString()}), 'PrivateSale is InActive');

            var tx = await astNft.connect(admin).minting([1, 3, 2, 0]);
            var txn = await tx.wait();


        });
    });
});