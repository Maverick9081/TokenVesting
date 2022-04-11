# TokenVesting


Deployed TokenVesting contract address : 0x827D96868427E45Bd6a24725c911F03866F7029e

Deployed Token address : 0x195EF29228E478f3c12C93592F7C9FF9c7844Bd9

This is a vesting smart contract with Dynamic TGE. It has 3 roles Advisor,Partnership and Mentor. Percentage of roles,cliff,and vesting duration are given below

Total TokenSupply : 100 *10**24

Advisor : 7.5% 
Partnership: 10%
Mentor: 5% 
Cliff : 90 days
Vesting Time : 365 days

To deploy contract the contract

1) Clone this repo using  this command
        git clone https://github.com/Maverick9081/TokenVesting.git

2) Install required dependencies using 
        npm install --save

3) setup .env file as shown in .env.example

4) run the following command to deploy the contract
    npx hardhat deployTokenVesting

5)run the following command to run tests      
    npx hardhat test 
