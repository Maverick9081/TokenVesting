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
    await tokenVesting.collect();
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("92500000000000000000000190");
  })

  it("Distributes right amount to role 1",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await tokenVesting.connect(add1).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal("9999999999999999999999990");
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("90000000000000000000000010");
  })

  it("Reward splits as number of particapants increse",async function(){
    const [owner, add1,add2] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await tokenVesting.addReceipient(add2.address,1);
    await tokenVesting.connect(add1).collect();
    await tokenVesting.connect(add2).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal(await niceToken.balanceOf(add2.address));
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("90000000000000000000000010");
  })

  it("Multiple roles reward distribution",async function(){
    const [add, add1,add2,add3] = await ethers.getSigners();

    await tokenVesting.addReceipient(add1.address,1);
    await tokenVesting.addReceipient(add2.address,1);
    await tokenVesting.connect(add1).collect();
    await tokenVesting.connect(add2).collect();
    expect(await niceToken.balanceOf(add1.address)).to.equal(await niceToken.balanceOf(add2.address));
    await tokenVesting.addReceipient(add.address,0);
    await tokenVesting.addReceipient(add3.address,0);
    await tokenVesting.connect(add).collect();
    await tokenVesting.connect(add3).collect();
    expect(await niceToken.balanceOf(add.address)).to.equal(await niceToken.balanceOf(add3.address));
    expect(await niceToken.balanceOf(vestingAddress)).to.equal("82600000000000000000000470");
})

})