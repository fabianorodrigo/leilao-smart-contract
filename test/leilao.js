var Leilao = artifacts.require("./Leilao.sol");

contract('Leilao', function (accounts) {
    it("A primeira conta deveria dar um Lance de 17 e como o incremento mínimo é 10, o maior lance fica sendo 10", async () => {
        //Pegando o contrato publicado na chain
        const contratoLeilao = await Leilao.deployed();
        //Dando um lance de 17 com a primeira conta
        //DICA TÉCNICA: Como o método 'darLance' muda o estado do contrato, ele é chamado diretamente, ou seja, não usa-se 'darLance.call'
        const transacao = await contratoLeilao.darLance({ value: 17, from: accounts[0] });
        //Verificando se a transacao contém o evento 'LogLance'
        assert.equal(transacao.logs.length,1,"Transação deveria ter um e apenas um evento");
        assert.equal(transacao.logs[0].event,"LogLance","O evento contido na transação deveria ser 'LogLance'");
        //Verificando valores
        const maiorLance = (await contratoLeilao.obterMaiorLanceAtual.call()).toNumber();
        assert.equal(maiorLance, 10, "O maior lance até agora deveria ser 10");
    });
});
