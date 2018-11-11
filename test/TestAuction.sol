pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Auction.sol";

contract TestAuction {

  address owner = 0x00c89FB22768128f06b779048ed482Bb876628D9;

  /***
   * Testa valor do maior lance atual em um contrato publicado na chain
   */
  function testInitialLatestBidUsingDeployedContract() public {
    Auction leilao = Auction(DeployedAddresses.Auction());

    uint expected = 0;

    Assert.equal(leilao.latestBid, expected, "O lance mais alto deveria ser zero inicialmente");
  }

  /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  function testInitiaLatestBidWithNewLeilao() public {
    Auction leilao = new Auction();

    uint expected = 0;

    Assert.equal(leilao.latestBid, expected, "O lance mais alto deveria ser zero inicialmente");
  }

   /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  /*function testDarLance() public payable {
    Leilao leilao = Leilao(DeployedAddresses.Leilao());
    leilao.darLance.value(17);
    Assert.equal(leilao.obterMaiorLanceAtual(), 17, "O lance mais alto deveria ser igual a 17");
  }*/

}