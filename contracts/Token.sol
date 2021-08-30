// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20PresetMinterPauser, Ownable {
  constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20PresetMinterPauser(name, symbol) {
    _mint(msg.sender, initialSupply);
  }
    
  function addMinter(address _addr) public onlyOwner{
    grantRole(MINTER_ROLE, _addr);
  }
}
