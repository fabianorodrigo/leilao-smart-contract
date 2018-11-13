const Auction = artifacts.require("./Auction.sol");

contract('Auction', function (accounts) {
  it("O lance inicial deve ser de 17 e o vendedor deve ser a primeira conta", async ()=> {
    //Pegando o contrato publicado na chain
    const contratoAuction = await Auction.deployed();
    //setando o valor do lance inicial mínimo com a primeira conta (que torna-se-á o vendedor)
    //DICA TÉCNICA: Como o método 'auction' muda o estado do contrato, ele é chamado diretamente, ou seja, não usa-se 'auction.call'
    await contratoAuction.auction(17, { value: 0, from: accounts[0] });
    //Verificando valores
    const latestBid = (await contratoAuction.getLatestBid.call()).toNumber();
    assert.equal(latestBid, 17000000000000000000, "O lance inicial mínimo deveria ser 17 ether");
    const seller = (await contratoAuction.getSeller.call());
    assert.equal(seller, accounts[0],"O vendedor deveria ser a primeira conta (accounts[0])")
  });
});
