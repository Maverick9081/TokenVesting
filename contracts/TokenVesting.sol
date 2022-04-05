pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting {

    uint private TotalSupply = 1e26;
    uint private denominator = 1000;
    uint private startTime = block.timestamp;
    uint private day = 86400;
    uint private cliff = startTime +(90 * day);
    uint private vestingDuration = cliff + (365 *day);
    IERC20 public NiceToken;
    
    constructor(IERC20 token){
        NiceToken = IERC20(token);
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

    function addReceipient(address person,Roles role)public {
        require(block.timestamp <cliff,"Can not add receipient after the cliff period");
        uint lastRewardUpdate = Shares[person].lastRewardUpdateTime;
        require(lastRewardUpdate == 0,"receipient should not be part of the program already");
        Shares[person].role = role;
        rewardPerRole[role] = getNewPercentage(role);
        Shares[person].lastRewardUpdateTime = cliff;
    }

    function collect() public {
        require(block.timestamp >= cliff, "Cliff period is not over yet");
        updatebalance(msg.sender);
        uint amount = balnaces[msg.sender];
        require(amount >0,"Can't withdraw 0 tokens");
        NiceToken.transfer(msg.sender, amount);
        balnaces[msg.sender] = 0; 
    }

    function getNewPercentage(Roles role)internal view returns(uint) {
        uint participants = roles[role] + 1;
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

    function updatebalance(address user)  internal{
        uint percentage = rewardPerRole[Shares[user].role];
        uint dailyReward = TotalSupply *percentage /(denominator *365);
        uint unPaidDays = (block.timestamp - Shares[user].lastRewardUpdateTime)/day; 
        balnaces[user] += dailyReward*unPaidDays;
        Shares[user].lastRewardUpdateTime = block.timestamp;
    }

    

}