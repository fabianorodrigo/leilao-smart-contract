pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Leilao.sol";

contract TestLeilao {

  address owner = 0x00c89FB22768128f06b779048ed482Bb876628D9;

  /***
   * Testa valor do maior lance atual em um contrato publicado na chain
   */
  function testInitialHiggestBindingBidUsingDeployedContract() public {
    Leilao leilao = Leilao(DeployedAddresses.Leilao());

    uint expected = 0;

    Assert.equal(leilao.maiorLance(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

  /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  function testInitialHiggestBindingBidWithNewLeilao() public {
    Leilao leilao = new Leilao(owner,10);

    uint expected = 0;

    Assert.equal(leilao.maiorLance(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

   /***
   * Testa valor do maior lance atual em um contrato instanciado localmente 
   */
  /*function testDarLance() public payable {
    Leilao leilao = Leilao(DeployedAddresses.Leilao());
    leilao.darLance.value(17);
    Assert.equal(leilao.maiorLance(), 17, "O lance mais alto deveria ser igual a 17");
  }*/

}