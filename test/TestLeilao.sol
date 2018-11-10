pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Leilao.sol";

contract TestLeilao {

  function testInitialHiggestBindingBidUsingDeployedContract() public {
    Leilao leilao = Leilao(DeployedAddresses.Leilao());

    uint expected = 0;

    Assert.equal(leilao.obterMaiorLanceAtual(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

  function testInitialHiggestBindingBidWithNewLeilao() public {
    Leilao leilao = new Leilao(0x00c89FB22768128f06b779048ed482Bb876628D9,10,99,100,"");

    uint expected = 0;

    Assert.equal(leilao.obterMaiorLanceAtual(), expected, "O lance mais alto deveria ser zero inicialmente");
  }

}