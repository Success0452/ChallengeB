// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;
 
import "hardhat/console.sol"; 
import "./ExampleExternalContract.sol"; 
 
 
contract Staker {
 
  ExampleExternalContract public exampleExternalContract; 
 
  uint256 public duedate = block.timestamp + 30 seconds;
  event Stake(address indexed sender, uint256 amount); 
  mapping(address => uint256) public userBalance; 
  uint256 public constant minimum = 1 ether; 
  
  modifier stakeIncomplete() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }
  
  modifier duedateReached( bool requireReached ) {
    uint256 timeLeft = timeLeft();
    if( requireReached ) {
      require(timeLeft == 0, "Due date not reached yet");
    } else {
      require(timeLeft > 0, "Due date is already passed");
    }
    _;
  }
  
  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function execute() public stakeIncomplete duedateReached(false) {
    uint256 contractBalance = address(this).balance;

    // check the contract has enough ETH to reach the treshold
    require(contractBalance >= minimum, "Minimum amount not reached");
 
    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }
 
  function stake() public payable stakeIncomplete duedateReached(false){
    userBalance[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }
 
  function withdraw() public stakeIncomplete duedateReached(true){
    uint256 userBalances = userBalance[msg.sender]; 
    require(userBalances > 0, "Balance too low");
 
    userBalance[msg.sender] = 0; 
    (bool sent,) = msg.sender.call{value: userBalances}("");
    require(sent, "Transfer failed");
  }
 
  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= duedate ) {
      return 0;
    } else {
      return duedate - block.timestamp;
    }
  }
}