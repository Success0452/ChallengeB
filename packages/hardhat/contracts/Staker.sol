//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 30 seconds;

  mapping ( address => uint256 ) public balances;

  bool private openForWithdraw;

  bool private isExecuted;

  event Stake(address indexed staker, uint256 indexed amount);
  event Withdraw(address indexed sender, uint256 amount);

  modifier canStake {
    require(block.timestamp <= deadline, "The deadline has passed!");
    _;
  }

  modifier deadlineReached() {
  uint256 timeRemaining = timeLeft();
    require(timeRemaining == 0, "Deadline is not reached yet");
    _;
}

modifier deadlineRemaining() {
  uint256 timeRemaining = timeLeft();
  require(timeRemaining > 0, "Deadline already reched");
  _;
  }

/*
* @notice Modifier that require the external contract to not be completed
*/
modifier stakeNotCompleted() {
  bool completed = exampleExternalContract.completed();
  require(!completed, "staking process is already completed");
  _;
}

  modifier canExecute {
    require(block.timestamp > deadline && !isExecuted, "The deadline has not yet passed, or the function has already been executed!");
    _;
  }

  modifier haveFunds(address _address) { 
    require (balances[_address] > 0, "You don't have funds in the Staker contract!"); 
    _;
  }

  modifier canWithdraw {
    require(openForWithdraw == true || block.timestamp > deadline, "You can not withdraw your funds at the moment!");
    _;
  }

   constructor(address exampleExternalContractAddress) public  {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable 
    canStake {
      balances[msg.sender] += msg.value;
  
      emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() external
    canExecute stakeNotCompleted{
      isExecuted = true;
      if(address(this).balance >= threshold) {
        exampleExternalContract.complete{value: address(this).balance}();
      } else {
        openForWithdraw = true;
      }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable withdrawer) public deadlineReached stakeNotCompleted {
    uint256 amount = balances[withdrawer];

    // check if the user have balance to withdraw
    require(amount > 0, "You don't have balance to withdraw");
    // reset the balance of the user
    balances[msg.sender] = 0;
    // transfer balance back to user
    (bool sent,) = withdrawer.call{value: amount}("");
    require(sent, "Failed to send user balance back to user");
    emit Withdraw(withdrawer, amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable 
    canStake {
      stake();
  }
}