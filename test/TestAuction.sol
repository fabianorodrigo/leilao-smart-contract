pragma solidity ^0.4.24;

import {Assert} from "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Auction.sol";

contract TestAuction {
  /***
   * Testa valor do maior lance atual em um contrato publicado na chain
   */
  function testInitialLatestBidUsingDeployedContract() payable public {
    Auction leilao = Auction(DeployedAddresses.Auction());

    uint256 expected = 0;

    Assert.equal(leilao.getLatestBid(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

  /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  function testInitiaLatestBidWithNewLeilao() public {
    Auction leilao = new Auction();

    uint expected = 0;

    Assert.equal(leilao.getLatestBid(), expected, "O lance mais alto deveria ser zero inicialmente");
  }
}