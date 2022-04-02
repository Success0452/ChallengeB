pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  
  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) { 
    yourToken = YourToken(tokenAddress); 
  } 
 
  // ToDo: create a payable buyTokens() function: 
  function buyTokens() public payable { 
 
    uint amountOfTokens = tokensPerEth * msg.value;  
    yourToken.transfer(msg.sender, amountOfTokens); 
    emit BuyTokens(msg.sender, msg.value, amountOfTokens); 
  } 
 
  // ToDo: create a withdraw() function that lets the owner withdraw ETH 
  function withdraw() public onlyOwner { 
 
    uint totalAmount = address(this).balance; 
    address owner=msg.sender; 
    require(totalAmount > 0, "Not enough Eth available"); 
    (bool success,) = owner.call{value: totalAmount}(""); 
    require(success, "Failed to withdraw Eth");
  }

  // ToDo: create a sellTokens() function: 
  function sellTokens(uint256 amount) public {
    uint256 saleAmount = amount/tokensPerEth;
    yourToken.transferFrom(msg.sender, address(this), amount);
    (bool sent, bytes memory data) = msg.sender.call{value: saleAmount}("");
    emit SellTokens(msg.sender, amount, saleAmount);
  }
} 