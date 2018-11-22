pragma solidity ^0.4.24;

contract Auction {
  address public manager;
  address public seller;
  uint public latestBid;
  address public latestBidder;
 
  constructor() public {
    manager = msg.sender;
  }

  function auction(uint bid) public {
    latestBid = bid * 1 ether; //1000000000000000000;
    seller = msg.sender;
  }
 
  function bid() public payable {
    require(msg.value > latestBid, "O valor do lance deve ser maior que o último");
 
    if (latestBidder != 0x0) {
      latestBidder.transfer(latestBid);
    }
    latestBidder = msg.sender;
    latestBid = msg.value;
  }
 
  function finishAuction() public restricted {
    seller.transfer(address(this).balance);
  }
 
  modifier restricted() {
    require(msg.sender == manager, "Somente o manager pode executar");
    _;
  }
}