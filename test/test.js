const { expect } = require("chai");
const { ethers } = require("hardhat");
let tokenVesting;
let niceToken;
let add1;
let add2;

beforeEach(async function(){
  const [add1,add2] = await ethers.getSigners();

  const token = await ethers.getContractFactory("NiceToken");
  niceToken = await token.deploy();
  tokenAddress = niceToken.address;

  const vesting = await ethers.getContractFactory("TokenVesting");
  tokenVesting = await vesting.deploy(tokenAddress,10000);
  vestingAddress = tokenVesting.address;

  niceToken.transfer(vestingAddress,"100000000000000000000000000");
})


describe("Distribution per role",async function(){

  it("Daily reward distribution", async function(){

    const [add1,add2] = await ethers.getSigners();
    await tokenVesting.addVesting(add1.address,1,0,5,200,50);
    await tokenVesting.connect(add1).collect(15);
    expect(await niceToken.balanceOf(add1.address)).to.equal("15");
    await hre.network.provider.send("evm_increaseTime",[519500]);
    const daily = await tokenVesting.connect(add1).tokensToBeClaimedDaily(add1.address);
    await tokenVesting.connect(add1).collect(daily);
    expect(await niceToken.balanceOf(add1.address)).to.equal(18);

  }) 

  it("Distribution after 5 days of cliff",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addVesting(add1.address,1,0,5,200,50);
    await tokenVesting.connect(add1).collect(20);
    expect(await niceToken.balanceOf(add1.address)).to.equal("20");
    await hre.network.provider.send("evm_increaseTime",[864000]);
    const daily = await tokenVesting.connect(add1).tokensToBeClaimedDaily(add1.address);
    await tokenVesting.connect(add1).collect(15);
    expect(await niceToken.balanceOf(add1.address)).to.equal(35);
  })

  it("After the reward duration ",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addVesting(add1.address,1,0,5,200,50);
    await tokenVesting.connect(add1).collect(20);
    expect(await niceToken.balanceOf(add1.address)).to.equal("20");
    await hre.network.provider.send("evm_increaseTime",[4752000]);
    const daily = await tokenVesting.connect(add1).tokensToBeClaimedDaily(add1.address);
    await tokenVesting.connect(add1).collect(180);
    expect(await niceToken.balanceOf(add1.address)).to.equal(200);
  })


describe("Revert Tests", async function(){

  it("should revert when someone other than owner tries to add participant", async function(){
    const [add1] = await ethers.getSigners();
    expect( tokenVesting.connect(add1).addVesting(add1.address,1,0,8,200,500)).to.be.revertedWith("Ownable: caller is not the owner");
  })

  it("should revert when adding same beneficiary twice ",async function(){
    const [add1] = await ethers.getSigners();
    
    await tokenVesting.addVesting(add1.address,0,9,8,2000,500);
    await expect( tokenVesting.addVesting(add1.address,0,8,8,200,50)).to.be
          .revertedWith("Beneficiary already have a vesting Schedule");
  })

  it ("should revert when Total amount is low w.r.t the vesting duration",async function(){
    const [add] = await ethers.getSigners();
    
    await expect(tokenVesting.addVesting(add.address,0,8,8,200,500)).to.be.revertedWith("Entered Amount is too low w.r.t duration")
  })

  it ("should revert when someone tries to withdraw 0 balance",async function(){
    const [add] = await ethers.getSigners();

    await expect(tokenVesting.connect(add).collect(0)).to.be.revertedWith("Can't withdraw 0 tokens");
  })
  
  it("should revert if someone tries to collect balance they don't have",async function(){
    const [add] = await ethers.getSigners();

    await expect(tokenVesting.connect(add).collect(50)).to.be.revertedWith("Not enough balance to withdraw")
  })

})
