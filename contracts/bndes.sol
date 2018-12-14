pragma experimental ABIEncoderV2;
pragma solidity ^0.4.24;

contract Owned {
	address internal owner = msg.sender;

	modifier onlyOwner 
	{ 
		require(msg.sender == owner); 
		_; 
	}

	event NewOwner(address indexed old, address indexed current);

    function getOwner() view public returns(address)
    {
    	return owner;
    }

    function setOwner(address _new) public onlyOwner 
    { 
    	if (owner != 0x0)
    		require(msg.sender == owner);

    	owner = _new; 
    	NewOwner(owner, _new); 
    }

} 

contract TokenERC20 
{
    string internal name;
    string internal symbol;
    uint8  internal decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 internal totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) internal balanceOf;

    mapping (address => mapping (address => uint256)) private allowance;    

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);    

    function TokenERC20 (uint256 initialSupply, string tokenName, 
        string tokenSymbol) public 
    {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only this by contract and contracts deriving from it can access
     */
    function _transfer(address _from, address _to, uint _value) internal 
    {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public pure returns (bool) 
    {
        // Fun��o n�o � utilizada no BNDES Token
        revert();
         
        //Coloquei esse c�digo s� para n�o dar warning
        if (_from != _to) return false;
        if (_from == _to) return false;
        if (_value == 0) return false;
        if (_value != 0) return false;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public pure returns (bool)
    {
        // N�o usada no BNDES Token ainda
        revert();

        //Coloquei esse c�digo s� para n�o dar warning
        if (_spender == 0) return false;
        if (_spender != 0) return false;
        if (_value == 0) return false;
        if (_value != 0) return false;
    }

    function getBalanceOf(address _addr) view public returns(uint256)
    {
        return balanceOf[_addr];
    }

    function getTotalSupply() view public returns (uint256)
    {
        return totalSupply;
    }

    function getName() view public returns (string)
    {
        return name;
    } 

    function getSymbol() view public returns (string)
    {
        return symbol;
    }

    function getDecimals() view public returns (uint8)
    {
        return decimals;
    }
    
}
 


contract BNDESToken is TokenERC20 (0,"BNDESToken", "BND"), Owned
{
    uint private versao = 20180625;

    struct PJInfo {
        uint cnpj;
        uint idSubcredito;
        uint cnpjOrigemRepasse;
        bool isRepassador;
    } 

    mapping (address => PJInfo) public pjsInfo;
    address[] public pjsInfoEnderecos; 

    event Cadastro(address endereco, uint cnpj, uint idSubcredito, uint cnpjOrigemRepasse, bool isRepassador);
    event Liberacao(uint cnpj, uint idSubcredito, uint256 valor);
    event Transferencia(uint fromCnpj, uint fromSubcredito, uint toCnpj, uint256 valor);
    event Repasse(uint fromCnpj, uint fromSubcredito, uint toCnpj, uint256 valor);
    event Resgate(uint cnpj, uint256 valor);
    event LiquidacaoResgate(uint160 hashResgate);
    event Troca(uint cnpj, uint idSubcredito);

    function BNDESToken() public
    {
        balanceOf[msg.sender] = 0;
        decimals = 2;
    }

    /**
    Associa um endere�o blockchain ao CNPJ
    */
    function cadastra(uint _cnpj, uint _idSubcredito, uint _cnpjOrigemRepasse, bool _isRepassador) public
    { 
        address endereco = msg.sender;

        // Endere�o n�o pode ter sido cadastrado anteriormente
        require(pjsInfo[endereco].cnpj == 0);

        pjsInfo[endereco] = PJInfo(_cnpj, _idSubcredito, _cnpjOrigemRepasse, _isRepassador);
        
        // N�o pode haver outro endere�o cadastrado para esse mesmo subcr�dito
        if (_idSubcredito > 0) {
            require (procuraPJInfo(_cnpj, _idSubcredito) == -1);
        }
        
        pjsInfoEnderecos.push(endereco);
        balanceOf[endereco] = 0;
        Cadastro(endereco, _cnpj, _idSubcredito, _cnpjOrigemRepasse, _isRepassador);
    }

    function trocaEnderecoDeCNPJSubcredito(address enderecoAntigo, address enderecoNovo, uint256 indiceEndAntigo) private
    {
        // Aponta o novo endere�o para o registro existente no mapping
        pjsInfo[enderecoNovo] = pjsInfo[enderecoAntigo];

        // Apaga o mapping do endere�o antigo
        pjsInfo[enderecoAntigo] = PJInfo(0, 0, 0, false);

        // Reusa o array de endere�os, reutilizando o espa�o do endere�o antigo para o novo
        pjsInfoEnderecos[indiceEndAntigo] = enderecoNovo;

        Cadastro(enderecoNovo, pjsInfo[enderecoNovo].cnpj, 
            pjsInfo[enderecoNovo].idSubcredito, 
            pjsInfo[enderecoNovo].cnpjOrigemRepasse, 
            pjsInfo[enderecoNovo].isRepassador);
    }

    /**
    Reassocia um cnpj/subcr�dito a um novo endere�o da blockchain (o sender)
    */
    function troca(uint _cnpj, uint _idSubcredito) public
    {
        address enderecoNovo = msg.sender;
        // O endere�o novo n�o pode estar sendo utilizado
        require(pjsInfo[enderecoNovo].cnpj == 0);

        // Tem que haver um endere�o associado a esse cnpj/subcr�dito
        int256 indiceDoPJResult = procuraPJInfo(_cnpj, _idSubcredito);
        require(indiceDoPJResult != -1);

        // IndiceDoPJResult pode ser negativo. IndiceDoPJ n�o, pois � �ndice de array
        uint256 indiceDoPJ = uint256(indiceDoPJResult);
        address enderecoAntigo = pjsInfoEnderecos[indiceDoPJ];

        // Se h� saldo no enderecoAntigo, precisa transferir
        if (getBalanceOf(enderecoAntigo) > 0) {
            _transfer(enderecoAntigo, enderecoNovo, getBalanceOf(enderecoAntigo));
        }
        
        trocaEnderecoDeCNPJSubcredito(enderecoAntigo, enderecoNovo, indiceDoPJ);

        Troca(_cnpj, _idSubcredito);
    }

    // function migraAPartirDeContrato(address _contratoAddr) onlyOwner public
    // {
        // BNDESToken contratoAntigo = BNDESToken (_contratoAddr);
        // if (contratoAntigo.getTotalSupply() < 0)

        // // Copia array
        // for (uint i = 0; i < contratoAntigo.getPjsInfoEnderecos().length; i++)
        // {
        //     pjsInfoEnderecos.push(contratoAntigo.getPjsInfoEnderecos()[i]);
        // }

        // // Copia cadastros e saldos
        // for (uint i2 = 0; i2 < pjsInfoEnderecos.length; i++)
        // {
        //     address addr = pjsInfoEnderecos[i];
        //     pjsInfo[addr] = contratoAntigo.getPJInfo(addr);
        //     balanceOf[addr] = contratoAntigo.getBalanceOf(addr);
    
        // }

        // contratoAntigo.setTotalSupply(totalSupply);
        // contratoAntigo.setName(name);
        // contratoAntigo.setSymbol(symbol);
        // contratoAntigo.setDecimals(decimals);
    // }

    function setTotalSupply(uint256 _value) onlyOwner public
    {
        totalSupply = _value;
    }

    function setName(string _name) onlyOwner public
    {
        name = _name;
    }

    function setSymbol(string _symbol) onlyOwner public
    {
        symbol = _symbol;
    }

    function setDecimals(uint8 _decimals) onlyOwner public
    {
        decimals = _decimals;
    }

    function procuraPJInfo(uint _cnpj, uint _idSubcredito) public view returns (int256 indiceDoPJ)  {

        int256 indiceEncontrado = -1;

        for (uint i = 0; i < pjsInfoEnderecos.length; i++) {
            if ( pjsInfo[pjsInfoEnderecos[i]].cnpj == _cnpj && pjsInfo[pjsInfoEnderecos[i]].idSubcredito == _idSubcredito ) {
                indiceEncontrado = int256(i);
                return indiceEncontrado;
             }
        }
        return indiceEncontrado;
    }

    function getVersao() view public returns (uint)
    {
        return versao;
    }

    function getCNPJ(address _addr) view public returns (uint)
    {
        return pjsInfo[_addr].cnpj;
    }

    function getSubcredito(address _addr) view public returns (uint)
    {
        return pjsInfo[_addr].idSubcredito;
    }

    function getPJInfo (address _addr) view public returns (PJInfo)
    {
        return pjsInfo[_addr];
    }

    function getPjsInfoEnderecos() view public returns(address[])
    {
        return pjsInfoEnderecos;
    }

    function transfer (address _to, uint256 _value) public
    {
        address from = msg.sender;

        // O cara n�o � louco de transferir para si mesmo!!!
        require(from != _to);

        // Se a origem eh o BNDES, eh uma liberacao`
        if (isBNDES(from))
        {
            // A conta de destino existe        
            require(pjsInfo[_to].cnpj != 0);

            require(isCliente(_to));

            mintToken(_to, _value);
            Transfer(from, _to, _value); // Evento do ERC-20 para manter o padr�o na visualiza��o da transa��o 
            Liberacao(pjsInfo[_to].cnpj, pjsInfo[_to].idSubcredito, _value);
        }
        else
        {
            // A conta de origem existe
            require(pjsInfo[from].cnpj != 0);
            if (isBNDES(_to))
            {
                // _to eh o BNDES. Entao eh resgate

                // Grante que a conta de origem eh um fornecedor
                require(isFornecedor(from));

                burnFrom(from, _value);
                Resgate(pjsInfo[from].cnpj, _value);
            }
            else            
            {
                // Se nem from nem to s�o o Banco, eh transferencia normal

                // A conta de destino existe        
                require(pjsInfo[_to].cnpj != 0);

                // A conta de destino existe        
                require(pjsInfo[_to].cnpj != 0);

                // Verifica se � transfer�ncia para repassador
                if (isRepassador(_to)) 
                {
                    require(isCliente(from));

                    // Garante que esse repassador � repassador do 
                    // conjunto cliente/subcr�dito
                    require(isRepassadorSubcredito(_to, from));
                    Repasse(pjsInfo[from].cnpj, pjsInfo[from].idSubcredito, pjsInfo[_to].cnpj, _value);
                }
                else
                {
                    require(isFornecedor(_to));

                    require(isCliente(from) || isRepassador(from));
                    Transferencia(pjsInfo[from].cnpj, pjsInfo[from].idSubcredito, pjsInfo[_to].cnpj, _value);
                }
  
                _transfer(msg.sender, _to, _value);
            }
        }
    }

    function isRepassador(address _addr) view public returns (bool)
    {
        if (_addr == owner)
            return false;
        return pjsInfo[_addr].isRepassador;
    }

    function isFornecedor(address _addr) view public returns (bool)
    {
        if (_addr == owner)
            return false;
        return pjsInfo[_addr].idSubcredito == 0;
    }

    function isCliente (address _addr) view public returns (bool)
    {
        if (_addr == owner)
            return false;
        return pjsInfo[_addr].idSubcredito != 0 && !pjsInfo[_addr].isRepassador;
    }

    function isBNDES(address _addr) view public returns (bool)
    {
        return (_addr == owner);
    }

    function isRepassadorSubcredito(address _addrRepassador, address _addrSubcredito) view public returns (bool)
    {
        if (_addrSubcredito == owner || _addrRepassador == owner) 
            return false;
        return pjsInfo[_addrRepassador].cnpjOrigemRepasse == pjsInfo[_addrSubcredito].cnpj 
            && pjsInfo[_addrRepassador].idSubcredito == pjsInfo[_addrSubcredito].idSubcredito;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) internal 
    {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        //require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        //allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
    }

    /**
     * This method does not belong to ERC20 standard, but is generic enough to be here
     *
     * @param target address which will receive the created tokens
     * @param mintedAmount of tokens created
     */
    function mintToken(address target, uint256 mintedAmount) onlyOwner internal
    {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
    }

    function notificaLiquidacaoResgate(uint160 hashResgate) onlyOwner public 
    {
        LiquidacaoResgate(hashResgate);
    }

    function setBalanceOf(address _addr, uint256 _value) onlyOwner public
    {
        require(_value >= 0);
        require(pjsInfo[_addr].cnpj != 0);

        uint256 delta = _value - balanceOf[_addr];
        totalSupply += delta;

        balanceOf[_addr] = _value;
    }

}