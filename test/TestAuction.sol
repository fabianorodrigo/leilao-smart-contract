pragma solidity ^0.4.24;

import {Assert} from "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Auction.sol";

/***
The rule of thumb is that smart contracts interacting with each other should be tested using Solidity. 
The rest can be tested using JavaScript, it is just easier. 
JavaScript testing is also closer to how you are going to use your contracts from the client application. 

https://michalzalecki.com/ethereum-test-driven-introduction-to-solidity-part-2/
*/


contract TestAuction {
  /***
   * Testa valor do maior lance atual em um contrato publicado na chain
   */
  function testInitialLatestBidUsingDeployedContract() payable public {
    Auction leilao = Auction(DeployedAddresses.Auction());

    uint256 expected = 0;

    Assert.equal(leilao.latestBid(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

  /***
   * Testa o manager em um contrato publicado na chain
   */
  function testManagerDeployedContract() payable public {
    Auction leilao = Auction(DeployedAddresses.Auction());

    Assert.equal(leilao.manager(), msg.sender, "O manager do leilão não é o mesmo que fez a publicação");
  }


  /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  function testInitiaLatestBidWithNewLeilao() public {
    Auction leilao = new Auction();

    uint expected = 0;

    Assert.equal(leilao.latestBid(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

  /***
   * Testa o manager em um contrato instanciado localmente 
   */
  function testManagerDeployedNewLeilao() payable public {
    Auction leilao = new Auction();

    Assert.equal(leilao.manager(), this, "O manager do leilão não é o mesmo que fez a publicação");
  }
}