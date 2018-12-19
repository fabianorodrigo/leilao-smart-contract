pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Leilao.sol";
import "./ThrowProxyHelper.sol";

// Contrato de teste que testa as exceções do contrato Leilão
contract TestThrowerLeilao {

  //TODO: Ver como capturar a exceçao do construtor
  /*
  function testThrowConstructorWithNoOwner() {
    Thrower thrower = new Thrower();
    ThrowProxyHelper throwProxy = new ThrowProxyHelper(address(thrower)); //set Thrower as the contract to forward requests to. The target.

    //prime the proxy.
    Thrower(address(throwProxy)).doThrow();
    //execute the call that is supposed to throw.
    //r will be false if it threw. r will be true if it didn't.
    //make sure you send enough gas for your contract method.
    bool r = throwProxy.execute.gas(200000)();

    Assert.isFalse(r, "Should be false, as it should throw");
  }*/

  
}