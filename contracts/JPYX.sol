//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract JPYX is ERC20PresetMinterPauser, Ownable {
  mapping (address => uint) private _interests;
  mapping(address => uint) private _lastBlocks;
  uint private _totalInterests;
  uint private _lastBlock;
  uint private _rate_denominator = 2628333;
  uint private _rate_numerator = 1;
  
  constructor(string memory _name, string memory _sym) ERC20PresetMinterPauser(_name, _sym) {}

  function totalInterests() public view returns (uint _interest) {
    uint plus = _rate_denominator == 0 ? 0 : totalSupply() * (block.number - _lastBlock) * _rate_numerator / _rate_denominator;
    _interest =  _totalInterests + plus;
  }

  function interestOf(address account) public view returns (uint _interest) {
    uint plus = _rate_denominator == 0 ? 0 : balanceOf(account) * (block.number - _lastBlocks[account]) * _rate_numerator / _rate_denominator;
    _interest =  _interests[account] + plus;
  }

  function calcMintable(uint amount, address minter) public view returns (uint _mintable) {
    _mintable =  amount * interestOf(minter) / totalInterests();
  }

  function reduceInterests(address minter) public onlyOwner{
    _totalInterests -= _interests[minter];
    _interests[minter] = 0;
  }

  function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
  ) internal override {
    _totalInterests = totalInterests();
    _interests[from] = interestOf(from);
    _interests[to] = interestOf(to);
  }

  function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal override {
    _lastBlock = block.number;
    _lastBlocks[from] = block.number;
    _lastBlocks[to] = block.number;
  }
  
}
