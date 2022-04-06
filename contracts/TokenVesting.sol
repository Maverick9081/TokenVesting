// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable{

    uint private TotalSupply = 1e26;
    uint private denominator = 1000;
    uint private startTime;
    IERC20 public NiceToken;

    
    /**
     *@dev sets the address of NiceToken
     *
     *@param token addres of token to distribute during vesting
     */
    constructor(IERC20 token) Ownable(){
        NiceToken = IERC20(token);
        startTime = block.timestamp;
    }

    enum Roles { 
        advisor,
        partnership,
        mentor
    }

    struct Receipients{
        Roles role;
        uint lastRewardUpdateTime;
    }

    mapping(address=>Receipients) private Shares;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public balnaces;
    mapping(Roles=>uint) public rewardPerRole;

    event TokenClaimed(address indexed by ,uint amount);
    event newReceipientAdded(address indexed receipient, Roles role);

    /**
     *@dev adds new Receipient to vesting according to role
     *
     *@param person is address of the person to be added to vesting
     *@param role is role to dedicate the person
     */
    function addReceipient(address person,Roles role)external onlyOwner {
        require(block.timestamp <cliff(),"Can not add receipient after the cliff period");
        uint lastRewardUpdate = Shares[person].lastRewardUpdateTime;
        require(lastRewardUpdate == 0,"receipient should not be part of the program already");
        Shares[person].role = role;
        roles[role]++;
        rewardPerRole[role] = getNewPercentage(role);
        Shares[person].lastRewardUpdateTime = cliff();
        emit newReceipientAdded(person, role);   
    }

    /**
     *@dev updates the balance og the caller and
     *transfers 'amount' of tokens to the caller
     *and sets the balance of the caller to '0'
     */
    function collect() external {
        require(block.timestamp > cliff(), "Cliff period is not over yet");
        updatebalance(msg.sender);
        uint amount = balnaces[msg.sender];
        require(amount >0,"Can't withdraw 0 tokens");
        unchecked{
            NiceToken.transfer(msg.sender,amount);
        }
        balnaces[msg.sender] = 0;

        emit TokenClaimed(msg.sender, amount);
    }

    /**
     *@dev Returns amount of token a user can claim
     */
    function viewClaimableRewards() external returns(uint) {
        require(block.timestamp > cliff(),"Cliff period is not over");
        updatebalance(msg.sender);
        uint amount = balnaces[msg.sender];
        return amount;
    }

    /**
     *@dev updates the percentage of tokens for a role 
     *as a new user joins vesting with that role
     *   
     *Returns uint value of new percentage for the role
     *   
     *@param role role of the new receipient  
    */
    function getNewPercentage(Roles role) internal view returns (uint) {
        uint participants = roles[role];
        uint rolePercentage;
        
        if(Roles.advisor == role){
            rolePercentage =75;
        }
        else if(Roles.partnership == role){
            rolePercentage =100;
        }
        else {
            rolePercentage = 50;
        }
        return rolePercentage/participants;
    }
    /**
     *@dev updates the balance of the user
     *calculates the unpaid tokens for the vesting
     *
     *@param user address of the user whose balance we want to update
     */
    function updatebalance(address user) internal {
        uint unPaidDays;
        uint percentage = rewardPerRole[Shares[user].role];
        uint dailyReward = TotalSupply *percentage /(denominator *365);

        if(block.timestamp >vestingDuration()){
            unPaidDays = (vestingDuration() - Shares[user].lastRewardUpdateTime)/1 days; 
        }
        else {
            unPaidDays = (block.timestamp - Shares[user].lastRewardUpdateTime)/1 days;
        } 
        balnaces[user] += dailyReward*unPaidDays;
        Shares[user].lastRewardUpdateTime += (unPaidDays*(1 days));
    }

    /**
     *@dev Returns the cliff time of the contract
     */
    function cliff() internal view returns(uint){
        return startTime + (90 days);
    }
    
    /**
     *dev Returns the vesting period for the tokens
     */
    function vestingDuration() internal view returns(uint){
        return cliff() + (365 days);
    }
}
