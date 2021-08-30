// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JPYX.sol";
import "hardhat/console.sol";

contract DEX is Ownable {
  mapping(address => uint) max_weight;
  uint public tvl;
  address public token;
  uint public fee;
  uint public profit;
  
  constructor(uint _fee) {
    require(_fee <= 10000, "fee must be less than or equal to 10000");
    fee = _fee;
    token = address(new JPYX("JPYX", "JPYX"));
  }
  
  function addToken(address _token, uint _max_weight) public onlyOwner {
    require(_max_weight <= 10000, "max_weight must be less than or equal to 10000");
    max_weight[_token] = _max_weight;
  }

  function getMintable (address minter) public view returns (uint mintable){
    mintable = JPYX(token).calcMintable(profit, minter);
  }
  
  function withdrawInterests() public {
    uint mintable = getMintable( msg.sender);
    profit -= mintable;
    JPYX(token).mint(msg.sender, mintable);
    JPYX(token).reduceInterests(msg.sender);
  }
  
  function addLiquidity(address[] memory _tokens, uint[] memory _amounts) public {
    require(_tokens.length > 0, "token length cannot be 0");
    require(_tokens.length == _amounts.length, "token length and amount length must be equal");
    uint total = tvl;
    uint mintable;
    for(uint i = 0; i < _tokens.length; i++){
      require(max_weight[_tokens[i]] != 0, "token not registered");
      total += _amounts[i];
    }
    for(uint i = 0; i < _tokens.length; i++){
      require((_amounts[i] + IERC20(_tokens[i]).balanceOf(address(this))) * 10000 / total <= max_weight[_tokens[i]], "token weight too much");
      tvl += _amounts[i];
      mintable += _amounts[i];
      IERC20(_tokens[i]).transferFrom(msg.sender, address(this), _amounts[i]);
    }
    JPYX(token).mint(msg.sender, mintable);
  }

  function removeLiquidity(address[] memory _tokens, uint[] memory _amounts) public {
    require(_tokens.length > 0, "token length cannot be 0");
    require(_tokens.length == _amounts.length, "token length and amount length must be equal");
    uint total = tvl;
    uint burnable;
    for(uint i = 0; i < _tokens.length; i++){
      require(max_weight[_tokens[i]] != 0, "token not registered");
      require(_amounts[i] <= IERC20(_tokens[i]).balanceOf(address(this)), "pool not enough");
      total -= _amounts[i];
      burnable += _amounts[i];
    }
    require(burnable <= JPYX(token).balanceOf(msg.sender), "balance not enough");
    
    for(uint i = 0; i < _tokens.length; i++){
      require((IERC20(_tokens[i]).balanceOf(address(this)) - _amounts[i]) * 10000 / total <= max_weight[_tokens[i]], "token weight too much");
      tvl -= _amounts[i];
      IERC20(_tokens[i]).transfer(msg.sender, _amounts[i]);
    }
    JPYX(token).burnFrom(msg.sender, burnable);
  }
  
  function isFee(address token_from, address token_to, uint _amount) public view returns (bool _isFee) {
    uint diff_before;
    uint diff_after;
    if(IERC20(token_to).balanceOf(address(this)) > IERC20(token_from).balanceOf(address(this))){
      diff_before = IERC20(token_to).balanceOf(address(this)) - IERC20(token_from).balanceOf(address(this));
    }else{
      diff_before = IERC20(token_from).balanceOf(address(this)) - IERC20(token_to).balanceOf(address(this));
    }

    if(IERC20(token_to).balanceOf(address(this)) + _amount > IERC20(token_from).balanceOf(address(this)) - _amount){
      diff_after = (IERC20(token_to).balanceOf(address(this)) + _amount) - (IERC20(token_from).balanceOf(address(this)) - _amount);
    }else{
      diff_after = (IERC20(token_from).balanceOf(address(this)) - _amount) - (IERC20(token_to).balanceOf(address(this)) + _amount);
    }
    
    _isFee = diff_before < diff_after;
  }
  
  function swap(address token_from, address token_to, uint _amount) public {
    require((_amount + IERC20(token_to).balanceOf(address(this))) * 10000 / (tvl + _amount) <= max_weight[token_to], "token weight too much");
    bool _isFee = isFee(token_from, token_to, _amount);
    uint _fee = _isFee ? (_amount * fee / 10000) : 0;
    IERC20(token_from).transferFrom(msg.sender, address(this), _amount);
    IERC20(token_to).transfer(msg.sender, _amount - _fee);
    profit += _fee;
  }
  
}
