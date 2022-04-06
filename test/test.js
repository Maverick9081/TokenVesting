const { expect } = require("chai");
const { ethers } = require("hardhat");
let tokenVesting;
let niceToken;

beforeEach(async function(){
  const [owner, add1,add2] = await ethers.getSigners();

  const token = await ethers.getContractFactory("NiceToken");
  niceToken = await token.deploy();
  tokenAddress = niceToken.address;


  const vesting = await ethers.getContractFactory("TokenVesting");
  tokenVesting = await vesting.deploy(tokenAddress);
  vestingAddress = tokenVesting.address;

  niceToken.transfer(vestingAddress,"100000000000000000000000000");
})


describe("Distribution per role",async function(){

  it("Distributes right amont to role 0", async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,0);
    await hre.network.provider.send("evm_increaseTime",[39312000]);
    await tokenVesting.connect(add1).collect();
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("92500000000000000000000190");
  })

  it("Distributes right amount to role 1",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await hre.network.provider.send("evm_increaseTime",[39312000]);
    await tokenVesting.connect(add1).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal("9999999999999999999999990");
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("90000000000000000000000010");
  })

  it("Reward splits as number of particapants increse for a role",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await tokenVesting.addReceipient(add2.address,1);
    await hre.network.provider.send("evm_increaseTime",[39312000]);
    await tokenVesting.connect(add1).collect();
    await tokenVesting.connect(add2).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal(await niceToken.balanceOf(add2.address));
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("90000000000000000000000010");
  })

  it("Multiple roles reward distribution",async function(){
    const [add, add1,add2,add3] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await tokenVesting.addReceipient(add2.address,1);
    await tokenVesting.addReceipient(add.address,0);
    await tokenVesting.addReceipient(add3.address,0);
    await hre.network.provider.send("evm_increaseTime",[39312000]);
    await tokenVesting.connect(add1).collect();
    await tokenVesting.connect(add2).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal(await niceToken.balanceOf(add2.address));
    
    await tokenVesting.connect(add).collect();
    await tokenVesting.connect(add3).collect();
    expect(await niceToken.balanceOf(add.address)).to.equal(await niceToken.balanceOf(add3.address));
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("82600000000000000000000470");
})

})

describe("Revertion Tests", async function(){

  it("should revert when someone other than owner tries to add participant", async function(){
    const [add1] = await ethers.getSigners();
    
    expect( tokenVesting.connect(add1).addReceipient(add1.address,1)).to.be.revertedWith("Ownable: caller is not the owner");
  })

  it("should revert when adding same particapnt twice ",async function(){
    const [add1] = await ethers.getSigners();
    
    await tokenVesting.addReceipient(add1.address,1);
    await expect( tokenVesting.addReceipient(add1.address,0)).to.be
          .revertedWith("receipient should not be part of the program already");
  })

  it ("should revert when owner tries to add participant after the cliff period",async function(){
    const [add] = await ethers.getSigners();
    await hre.network.provider.send("evm_increaseTime",[7776000]);
    await expect(tokenVesting.addReceipient(add.address,0)).to.be.revertedWith("Can not add receipient after the cliff period")
  })

  it ("should revert when someone tries to withdraw 0 balance",async function(){
    const [add] = await ethers.getSigners();
    await hre.network.provider.send("evm_increaseTime",[7776000])
    await expect(tokenVesting.connect(add).collect()).to.be.revertedWith("Can't withdraw 0 tokens");
  })
  
  it("should revert if someone tries to collect reward before cliff period ends",async function(){
    const [add] = await ethers.getSigners();

    await expect(tokenVesting.connect(add).collect()).to.be.revertedWith("Cliff period is not over yet")
  })

})
