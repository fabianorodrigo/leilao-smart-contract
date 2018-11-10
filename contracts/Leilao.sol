pragma solidity ^0.4.2;

contract Leilao {

    // static
    address public owner;
    uint public blocoInicial;
    uint public blocoFinal;
    string public ipfsHash;
    uint public bidIncrement;

    // state
    bool public cancelado;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    uint public highestBindingBid;
    bool ownerHasWithdrawn;

    constructor(address _owner, uint _bidIncrement, uint _blocoInicial, uint _blocoFinal, string _ipfsHash) public {
        if (_blocoInicial >= _blocoFinal) revert("Bloco inicial não pode ser maior ou igual ao final");
        if (_blocoInicial < block.number) revert("Bloco inicial não pode ser maior que o bloco atual");
        if (_owner == 0) revert("Um leilão não pode ser criado sem um Owner");

        owner = _owner;
        bidIncrement = _bidIncrement;
        blocoInicial = _blocoInicial;
        blocoFinal = _blocoFinal;
        ipfsHash = _ipfsHash;
    }

    function obterMaiorLanceAtual() public view returns(uint){
        return highestBindingBid;
    }

    modifier somenteOwner {
        if (msg.sender != owner) revert("Ação permitida somente ao Owner do Leilão");
        _;
    }

    modifier somenteNaoOwner {
        if (msg.sender == owner) revert("Ação não permitida ao Owner do Leilão");
        _;
    }

    modifier somenteAposComecar {
        if (block.number < blocoInicial) revert("Ação permitida apenas após o início do Leilão");
        _;
    }

    modifier somenteAntesEncerrar {
        if (block.number > blocoFinal) revert("Leilão já foi encerrado");
        _;
    }

    modifier somenteNaoCancelado {
        if (cancelado) revert("Leilão foi cancelado");
        _;
    }

    modifier somenteFinalizadoOuCancelado {
        if (block.number < blocoFinal && !cancelado) revert("Leilão ainda está em andamento");
        _;
    }

    function darLance() public
        payable
        somenteAposComecar
        somenteAntesEncerrar
        somenteNaoCancelado
        somenteNaoOwner returns (bool success)  {

        // Rejeita lances de 0 ETH
        if (msg.value == 0) revert("Lance deve ser maior que 0 (zero)");

        // Calcula o lance total dos usuários basead no montante corrente que eles enviaram para o contrato
        // mais o montante que eles está enviando agora
        uint newBid = fundsByBidder[msg.sender] + msg.value;

        // Se o usuário não está cobrindo o lance mais alto, rejeita o lance
        if (newBid <= highestBindingBid) revert("Lance não cobre o maior lance do leilão");

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you already have.

            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
            }
            highestBid = newBid;
        }

        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }

    function sacar() public 
        somenteFinalizadoOuCancelado
        returns (bool success)  {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (cancelado) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } else {
            // the auction finished without being canceled

            if (msg.sender == owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }

            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) revert("Montante zero");

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // Envia os fundos para a conta de destino
        if (!msg.sender.send(withdrawalAmount)) revert("Falha ao realizar transação");

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;

    }


    function cancelarLeilao()  public 
    somenteOwner
    somenteAntesEncerrar
    somenteNaoCancelado
    returns (bool success)
    {
        cancelado = true;
        emit LogCanceled();
        return true;
    }

    function min(uint a, uint b) private pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
}