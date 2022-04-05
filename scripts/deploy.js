const { getAccount, getEnvVariable } = require("./helper");

task("deployNiceToken").setAction(async function(taskArguements,hre) {
  const niceTokenContract = await hre.ethers.getContractFactory("NiceToken",getAccount());
  const niceToken = await niceTokenContract.deploy();
console.log(`contract deployed at address : ${niceToken.address}`);
});

task("deployTokenVesting").setAction(async function(taskArguements,hre) {
  const tokenVestingContract = await hre.ethers.getContractFactory("TokenVesting",getAccount());
  const tokenVesting = await tokenVestingContract.deploy(getEnvVariable("NICE_TOKEN"));
console.log(`contract deployed at address : ${tokenVesting.address}`);
});