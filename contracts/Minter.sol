// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Minter is ChainlinkClient {
  string endpoint;
  address token;
  using Chainlink for Chainlink.Request;
  mapping (bytes32 => string) paymentIds;
  mapping (bytes32 => address) minters;
  mapping (string => bool) public minted;
  uint256 public volume;
  address private oracle;
  bytes32 private jobId;
  uint256 private fee;
  constructor(string memory _endpoint, address _token) {
    token = _token;
    endpoint = _endpoint;
    setPublicChainlinkToken();
    oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
    jobId = "d5270d1c311941d0b08bead21fea7747";
    fee = 0.1 * 10 ** 18;
  }
  
  function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d, e));
  }
  
  function toStr(address account) public pure returns(string memory) {
    return toStr(abi.encodePacked(account));
  }
  
  function toStr(uint256 value) public pure returns(string memory) {
    return toStr(abi.encodePacked(value));
  }

  function toStr(bytes32 value) public pure returns(string memory) {
    return toStr(abi.encodePacked(value));
  }

  function toStr(bytes memory data) public pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
      str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
      str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }
  
  function mint(string memory paymentId) public returns (bytes32 requestId) 
  {
    require(minted[paymentId] == false, "alrady minted");
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
    request.add("get", append(endpoint, "?merchant-payment-id=", paymentId, "&address=",  toStr(msg.sender)));
    request.add("path", "amount");
    int timesAmount = 10**18;
    request.addInt("times", timesAmount);
    requestId = sendChainlinkRequestTo(oracle, request, fee);
    paymentIds[requestId] = paymentId;
    minters[requestId] = msg.sender;
    return requestId;
  }
    
  function fulfill(bytes32 _requestId, uint _amount) public recordChainlinkFulfillment(_requestId)
  {
    require(_amount > 0, "amount is zero");
    require(minted[paymentIds[_requestId]] == false, "already minted");
    ERC20PresetMinterPauser(token).mint(minters[_requestId], _amount);
    minted[paymentIds[_requestId]] = true;
  }
}
