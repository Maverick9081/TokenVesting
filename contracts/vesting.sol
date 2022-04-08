// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable{

    uint private denominator = 1000;
    IERC20 public NiceToken;
    uint private totalSupply;

    
    /**
     *@dev sets the address of NiceToken
     *
     *@param token address s of token to distribute during vesting
     */
    constructor(IERC20 token,uint totalSupply) Ownable(){
        NiceToken = IERC20(token);
        totalSupply = totalSupply;
    }

    enum Roles { 
        advisor,
        partnership,
        mentor
    }
        
    struct Vesting {
        Roles role;
        uint startTime;
        uint cliff;
        uint totalAmount;
        uint vestedAmount;                                          
        uint lastRewardUpdateTime;
        uint tgePercentage;
        uint duration;
        bool tgeClaimed;
    }

    mapping(address=>Vesting) public VestingSchedule;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public Balances;
    mapping(address =>uint) public vestingCount;

    event TokenClaimed(address indexed by ,uint amount);
    event newRecipientAdded(address indexed recipient, Roles role,uint totalAmount,uint duration,uint cliff);

    function addVesting(
        address beneficiary,
        Roles role,
        uint startTime,
        uint cliff,
        uint totalAmount,
        uint duration
        )
        external onlyOwner {

        bool minimumAmount = getMinimumAmount(totalAmount, duration);
        require(minimumAmount,"Entered Amount is too low w.r.t duration");
        require(VestingSchedule[beneficiary].startTime ==  0,"Beneficiary already have a vesting Schedule");                
        VestingSchedule[beneficiary] = Vesting(
            role,
            block.timestamp + (startTime* 1 days),
            block.timestamp + (startTime + cliff)*1 days,
            totalAmount,
            0,
            block.timestamp +(startTime +cliff)*1 days,
            getTgePercentage(role),
            duration * 1 days,
            false
        );
        emit newRecipientAdded(beneficiary, role, totalAmount,duration,cliff);
    }

    function updateBalance(address user) internal {
        uint time = VestingSchedule[user].cliff;

        if(block.timestamp < time && VestingSchedule[user].tgeClaimed == false){
            uint amount = VestingSchedule[user].totalAmount *VestingSchedule[user].tgePercentage /denominator;
            Balances[user] += amount;

            VestingSchedule[user].vestedAmount += amount;
            VestingSchedule[user].tgeClaimed = true;
        }

        else if(block.timestamp > time && block.timestamp < time+ VestingSchedule[user].duration) {
                if(VestingSchedule[user].tgeClaimed ==false)
                {
                    uint tgeAmount = VestingSchedule[user].totalAmount * VestingSchedule[user].tgePercentage / denominator;
                    Balances[user] += tgeAmount;
                    VestingSchedule[user].tgeClaimed = true;
                }
            uint dailyReward = tokensToBeClaimedDaily(user);
            uint unPaidDays = (block.timestamp-VestingSchedule[user].lastRewardUpdateTime)/1 days; 
            uint amount = dailyReward * unPaidDays;
            Balances[user] += amount;

            VestingSchedule[user].lastRewardUpdateTime = block.timestamp;
            VestingSchedule[user].vestedAmount += amount; 
        }

        else if(block.timestamp > time + VestingSchedule[user].duration)
        {
            uint amount = VestingSchedule[user].totalAmount - VestingSchedule[user].vestedAmount;
            Balances[user] = amount;

            VestingSchedule[user].lastRewardUpdateTime = block.timestamp;
            VestingSchedule[user].vestedAmount += amount;     
        }
        return;
    }

    /**
     *@dev updates the balance og the caller and
     *transfers 'amount' of tokens to the caller
     *and sets the balance of the caller to '0'
     */
    function collect() external {

        updateBalance(msg.sender);
        uint amount = Balances[msg.sender];
        require(amount >0,"Can't withdraw 0 tokens"); 
        unchecked{
            NiceToken.transfer(msg.sender,amount);
        }
        Balances[msg.sender] = 0;

        emit TokenClaimed(msg.sender, amount);
    }

    /**
     *@dev Returns amount of token a user can claim
     */
    function viewClaimableRewards() external returns(uint) {
        updateBalance(msg.sender);
        uint amount = Balances[msg.sender];
        return amount;
    }

    function tokensToBeClaimedDaily(address user) public  view returns (uint) {
        uint totalAmount = VestingSchedule[user].totalAmount;
        uint tgeAmount = (totalAmount * VestingSchedule[user].tgePercentage)/denominator;
        uint dailyReward = (totalAmount-tgeAmount)/VestingSchedule[user].duration;
        return dailyReward;
    }
    /**
     *@dev updates the percentage of tokens for a role 
     *as a new user joins vesting with that role
     *   
     *Returns uint value of new percentage for the role
     *   
     *@param role role of the new recipient  
    */
    function getTgePercentage(Roles role) internal view returns (uint) {
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
        return rolePercentage;
    }

    function getMinimumAmount(uint totalAmount,uint duration) internal returns(bool){
        if(totalAmount/(duration *1 days) >=2){
            return true;
        }
        else{
            return false;
        }
    }
    
}
