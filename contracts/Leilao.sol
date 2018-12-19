pragma solidity ^0.4.2;

contract Leilao {

  // static
  address public owner;
  uint public incrementoMinimo;
  // state
  bool public cancelado;
  bool public finalizado;
  address public participanteMaiorLance;
  mapping(address => uint256) public fundosPorParticipante;
  uint public maiorLance;
  bool ownerSacou;

  constructor(address _owner, uint _incrementoMinimo) public {
    if (_owner == 0) revert("Um leilão não pode ser criado sem um Owner");

    owner = _owner;
    incrementoMinimo = _incrementoMinimo;
  }

  modifier somenteOwner {
    if (msg.sender != owner) revert("Ação permitida somente ao Owner do Leilão");
    _;
  }

  modifier somenteNaoOwner {
    if (msg.sender == owner) revert("Ação não permitida ao Owner do Leilão");
    _;
  }

  modifier somenteNaoCancelado {
    if (cancelado) revert("Leilão foi cancelado");
    _;
  }

  modifier somenteFinalizadoOuCancelado {
    if (!finalizado && !cancelado) revert("Leilão ainda está em andamento");
    _;
  }

  function darLance() public
    payable
    somenteNaoCancelado
    somenteNaoOwner returns (bool success)  {

    // Rejeita lances de 0 ETH
    if (msg.value == 0) revert("Lance deve ser maior que 0 (zero)");

    // Calcula o lance total dos usuários baseado no montante corrente que eles enviaram para o contrato
    // mais o montante que eles está enviando agora
    uint novoLance = fundosPorParticipante[msg.sender] + msg.value;

    // Se o usuário não está cobrindo o lance mais alto, rejeita o lance
    if (novoLance <= maiorLance) revert("Lance não cobre o maior lance do leilão");

    // Pega o maior lance anterior (antes de atualizar fundosPorParticipante, no caso do msg.sender ser o
    // participanteMaiorLance e está apenas aumentando seu lance máximo).
    uint lanceMaisAlto = fundosPorParticipante[participanteMaiorLance];

    fundosPorParticipante[msg.sender] = novoLance;

    if (novoLance <= lanceMaisAlto) {
      // se o participante cobriu o {maiorLance} mas não cobriu o {lanceMaisAlto}, nós
      // simplesmente aumentamos o {maiorLance} e não alteramos o {participanteMaiorLance}

      // note que este caso é impossível se msg.sender == participanteMaiorLance pois você nunca
      // poderá dar um lance menor de ETH que você já deu

      maiorLance = min(novoLance + incrementoMinimo, lanceMaisAlto);
    } else {
      // Se msg.sender já é o participante com maior lance, eles devem simplesmente aumentar
      // o lance máximo, neste caso, nós não aumentamos o {maiorLance}

      // Se o usuário NÃO é o participante que deu o maior lance, e superou {lanceMaisAlto}, nós
      // setamos ele como o novo participante com maior lance e recalculamos {maiorLance}

      if (msg.sender != participanteMaiorLance) {
        participanteMaiorLance = msg.sender;
        maiorLance = min(novoLance, lanceMaisAlto + incrementoMinimo);
      }
      lanceMaisAlto = novoLance;
    }
    msg.sender.transfer(msg.value);

    emit LogLance(msg.sender, novoLance, participanteMaiorLance, lanceMaisAlto, maiorLance);
    return true;
  }

  function sacar() public 
    somenteFinalizadoOuCancelado
    returns (bool success)  {
    address contaSaque;
    uint montanteSaque;

    if (cancelado) {
      // Se o leilão foi cancelado, todos estão autorizados a sacar seus respectivos fundos
      contaSaque = msg.sender;
      montanteSaque = fundosPorParticipante[contaSaque];

    } else {
      // Se o leilão encerrou sem ser cancelado

      if (msg.sender == owner) {
        // o owner do leilão pode sacar a quantida {maiorLance}
        contaSaque = participanteMaiorLance;
        montanteSaque = maiorLance;
        ownerSacou = true;

      } else if (msg.sender == participanteMaiorLance) {
        // O participante que deu o maior lance pode sacar apenas a quantia que é a diferença
        //entre sua maior oferta e o {maiorLance}
        contaSaque = participanteMaiorLance;
        if (ownerSacou) { //NÃO ENTENDI ESSA DIFERENCIAÇÃO
          montanteSaque = fundosPorParticipante[participanteMaiorLance];
        } else {
          montanteSaque = fundosPorParticipante[participanteMaiorLance] - maiorLance;
        }

      } else {
        // QUalquer um que participou mas não ganhou o leilão, pode sacar montante total
        contaSaque = msg.sender;
        montanteSaque = fundosPorParticipante[contaSaque];
      }
    }

    if (montanteSaque == 0) revert("Montante zero");

    fundosPorParticipante[contaSaque] -= montanteSaque;

    // Envia os fundos para a conta de destino
    if (!msg.sender.send(montanteSaque)) revert("Falha ao realizar transação");

    emit LogSaque(msg.sender, contaSaque, montanteSaque);

    return true;

  }


  function cancelarLeilao()  public 
  somenteOwner
  somenteNaoCancelado
  returns (bool success)
  {
    cancelado = true;
    emit LogCancelamento();
    return true;
  }

  function finalizarLeilao()  public 
  somenteOwner
  somenteNaoCancelado
  returns (bool success)
  {
    finalizado = true;
    emit LogEncerramento();
    return true;
  }

  function min(uint a, uint b) private pure
    returns (uint)
  {
    if (a < b) return a;
    return b;
  }

  event LogLance(address participante, uint lance, address participanteMaiorLance, uint lanceMaisAlto, uint maiorLance);
  event LogSaque(address sacador, address contaSaque, uint montante);
  event LogCancelamento();
  event LogEncerramento();
}