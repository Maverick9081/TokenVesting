// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable{

    uint private denominator = 1000;
    IERC20 public NiceToken;

    
    /**
     *@dev sets the address of NiceToken
     *
     *@param token address s of token to distribute during vesting
     */
    constructor(IERC20 token,uint Supply) Ownable(){
        NiceToken = IERC20(token);
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
        bool revoked;
    }

    mapping(address=>Vesting) public VestingSchedule;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public Balances;
    mapping(address =>uint) public vestingCount;

    event TokenClaimed(address indexed by ,uint amount);
    event newRecipientAdded(address indexed recipient, Roles role,uint totalAmount,uint duration,uint cliff);

    /// @notice Add a new beneficiary to the vesting 

    /// @param beneficiary address of the beneficiary to be added to vesting 
    /// @param role role of the beneficiary
    /// @param startTime start time of vesting after adding the beneficiary In Days
    /// @param cliff cliff time between start time and vesting time
    /// @param totalAmount total Amount of tokens to be vested
    /// @param duration duration of vesting after the cliff period   
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
            duration,
            false,
            false
        );
        emit newRecipientAdded(beneficiary, role, totalAmount,duration,cliff);
    }
    /**
     *@dev updates the balance of user according to their total amount and role
     *
     *@param user address of the user
     */
    function updateBalance(address user) internal {
        if(VestingSchedule[user].revoked){
            return;
        }
        
        uint time = VestingSchedule[user].cliff;
        if(block.timestamp < time && VestingSchedule[user].tgeClaimed == false){
            uint amount = VestingSchedule[user].totalAmount *VestingSchedule[user].tgePercentage /denominator;
            Balances[user] += amount;

            VestingSchedule[user].vestedAmount += amount;
            VestingSchedule[user].tgeClaimed = true;
        }

        else if(block.timestamp > time && block.timestamp < time+ VestingSchedule[user].duration*1 days) {
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
    function collect(uint amount) external {
        
        require(amount >0,"Can't withdraw 0 tokens");
        updateBalance(msg.sender);
        uint withdrawAbleAmount = Balances[msg.sender];
        require(amount <=withdrawAbleAmount,"Not enough balance to withdraw");
         
        unchecked{
            NiceToken.transfer(msg.sender,amount);
        }
        Balances[msg.sender] -= amount;

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
    
    /**
     *Returns daily claimable tokens for that user 
     */
    function tokensToBeClaimedDaily(address user) public  view returns (uint) {
        uint totalAmount = VestingSchedule[user].totalAmount;
        uint tgeAmount = (totalAmount * VestingSchedule[user].tgePercentage)/denominator;
        uint dailyReward = (totalAmount-tgeAmount)/VestingSchedule[user].duration;
        return dailyReward;
    }
    /**
     *@dev revokes vesting of the user 
     *
     *@param beneficiary address of the beneficiary 
     */
    function revokeVesting(address beneficiary) external onlyOwner {
        require(!VestingSchedule[beneficiary].revoked,"vesting schedule should not be reovked already");
        updateBalance(beneficiary);
        VestingSchedule[beneficiary].revoked = true;
    }

    /**
     *@dev updates the percentage of tokens for a role 
     *as a new user joins vesting with that role
     *   
     *Returns uint value of new percentage for the role
     *   
     *@param role role of the new recipient  
    */
    function getTgePercentage(Roles role) internal pure returns (uint) {
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
    /**
     *@dev checks if the total amount and duration ration is big enough
     *to ensure daily rewards   
     *
     *Returns bool
     *@param totalAmount total amount of tokens to be vested
     *@param duration duration of vesting after the cliff period   
     */

    function getMinimumAmount(uint totalAmount,uint duration) internal pure returns(bool){
        if(totalAmount/duration >= 2){
            return true;
        }
        else{
            return false;
        }
    }
    
}
