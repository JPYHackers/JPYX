// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet {
  uint amount;
  uint delay;
  mapping(address => mapping(address => uint)) last;
  
  constructor(uint _amount, uint _delay) {
    amount = _amount;
    delay = _delay;
  }
  
  function get(address _token) public {
    require(block.number >= last[msg.sender][_token] + delay, "too early");
    uint pool = IERC20(_token).balanceOf(address(this));
    require(pool > 0, "no token pooled");
    IERC20(_token).transfer(msg.sender, amount > pool ? pool : amount);
    last[msg.sender][_token] = block.number;
  }
  
}
