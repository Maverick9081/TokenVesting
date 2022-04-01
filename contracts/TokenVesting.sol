pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting {

    uint256 private TotalSupply = 1e26;
    uint256 private denominator = 1000;
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
        partnerShip,
        mentor
    }

    struct Receipients{
        Roles role;
        uint percentages;
        uint lastRewardUpdateTime;
    }

    mapping(address=>Receipients) private Shares;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public balnaces;

    function getPercentage () public view returns(uint) {
        return Shares[msg.sender].percentages;
    }

    function addReceipient(address person,Roles role)public {
        Shares[person].role = role;
        Shares[person].percentages =getNewPercentage(role);
        Shares[person].lastRewardUpdateTime = block.timestamp;
    }

    function shares(Roles role)internal  pure returns(uint){
        if(Roles.advisor == role){
            return 75;
        }
        else if(Roles.partnerShip == role){
            return 100;
        }
        return 50;
    } 

    function getNewPercentage(Roles role)public view returns(uint) {
        uint participants = roles[role];
        return shares(role)/participants;
    }

    function updatebalance(address user)  internal{
        uint unPaidDays = (block.timestamp - Shares[user].lastRewardUpdateTime)/day; 
        balnaces[user] += getdaily(user)*unPaidDays;
        Shares[user].lastRewardUpdateTime = block.timestamp;
    }

    function getdaily(address user)public view returns(uint) {
        uint percentage = getPercentage();
        uint dailyReward = TotalSupply *percentage /(denominator *365);
        return dailyReward;
    }

    function collect() public {
        require(block.timestamp >= cliff, "Cliff period is not over yet");
        updatebalance(msg.sender);
        uint amount = balnaces[msg.sender];
        NiceToken.transfer(msg.sender, amount);
        balnaces[msg.sender] -= amount; 
    }



}