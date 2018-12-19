const FINNEY = 10**15;

var Leilao = artifacts.require("./Leilao.sol");

contract('Leilao', function (accounts) {
    it("A primeira conta deveria dar um Lance de 17 e como o incremento mínimo é 10, o maior lance fica sendo 10", async () => {
        //Pegando o contrato publicado na chain
        const contratoLeilao = await Leilao.deployed();
        //Dando um lance de 17 com a primeira conta
        //DICA TÉCNICA: Como o método 'darLance' muda o estado do contrato, ele é chamado diretamente, ou seja, não usa-se 'darLance.call'
        const transacao = await contratoLeilao.darLance({ value: 17, from: accounts[0] });
        console.log('conta 0 ',accounts[0])
        //Verificando se a transacao contém o evento 'LogLance'
        assert.equal(transacao.logs.length, 1, "Transação deveria ter um e apenas um evento");
        assert.equal(transacao.logs[0].event, "LogLance", "O evento contido na transação deveria ser 'LogLance'");
        //Verificando valores
        const maiorLance = (await contratoLeilao.maiorLance.call()).toNumber();
        assert.equal(maiorLance, 10, "O maior lance até agora deveria ser 10");
    });

    it("Um lance de valor ZERO deveria ser rejeitado", async () => {
        //Pegando o contrato publicado na chain
        const contratoLeilao = await Leilao.deployed();
        let transacao = null;
        let ocorreuExcecao = false;
        try {
            //Dando um lance de ZERO com a primeira conta
            //DICA TÉCNICA: Como o método 'darLance' muda o estado do contrato, ele é chamado diretamente, ou seja, não usa-se 'darLance.call'
            transacao = await contratoLeilao.darLance({ value: 0, from: accounts[0] });
            //assert(false,"Era pra ocorrer uma exceção");
        } catch (e) {
            ocorreuExcecao = true;
            assert(e.message.indexOf(`revert Lance deve ser maior que 0 (zero)`) > -1,`A exceção que ocorreu não foi a esperada`);
            //console.log('excecao', e.message, e.toString())
        }
        assert(ocorreuExcecao,`O lance de valor ZERO não foi revertido`);
    });


    it("Um lance do próprio dono do Leilão deveria ser rejeitado", async () => {
        //Pegando o contrato publicado na chain
        const contratoLeilao = await Leilao.deployed();
        let transacao = null;
        let ocorreuExcecao = false;
        try {
            //Dando um lance com o próprio OWNER do leilão, 0x00c89FB22768128f06b779048ed482Bb876628D9, deveria gerar excecao
            //DICA TÉCNICA: Como o método 'darLance' muda o estado do contrato, ele é chamado diretamente, ou seja, não usa-se 'darLance.call'
            transacao = await contratoLeilao.darLance({ value: 10* FINNEY, from: accounts[0] });
            //assert(false,"Era pra ocorrer uma exceção");
        } catch (e) {
            ocorreuExcecao = true;
            console.log(e.message)
            assert(e.message.indexOf(`revert Lance não pode ser dado pelo OWNER do leilão: 0x00c89FB22768128f06b779048ed482Bb876628D9`) > -1,`A exceção que ocorreu não foi a esperada`);
            //console.log('excecao', e.message, e.toString())
        }
        assert(ocorreuExcecao,`O lance da conta OWNER do leilão, 0x00c89FB22768128f06b779048ed482Bb876628D9,  não foi revertido`);
    });
});
