pragma solidity ^0.4.21;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }
}

contract ForceSeller is Ownable {
  function setDAO(address _DAOAddress) external;
}

contract Token {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract ForceToken is Token, Ownable {
  function setDAO(address _DAOAddress) external;
  function serviceTransfer(address _from, address _to, uint _value) external returns (bool);
  function holders(uint _id) external view returns (address);
  function holdersCount() external view returns (uint);
  function mint(address _to, uint _amount) external returns (bool);
}


//
//contract tokenRecipient {
//  event ReceivedEther(address sender, uint amount);
//  event ReceivedTokens(address _from, uint256 _value, address _token, bytes _extraData);
//
//  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external {
//    Token t = Token(_token);
//    require(t.transferFrom(_from, this, _value));
//    emit ReceivedTokens(_from, _value, _token, _extraData);
//  }
//
//  function tokenFallback(address _from, uint256 _value, bytes _extraData) external {
//    emit ReceivedTokens(_from, _value, msg.sender, _extraData);
//  }
//
//  function() payable external {
//    emit ReceivedEther(msg.sender, msg.value);
//  }
//}

contract DAOHierarchy is Ownable {
  address public DAO; // DAO contract
  struct Department {
    bool exists;
    uint index;
    address head; //адрес вышестоящего подразделения
    uint level; //уровень иерархии
    uint levelIndex; //id в списке уровня ирерахии
    uint subIndex; //id в списке подчиенных вышестоящего отдела
    mapping (uint => address) subs;
    uint subsCount;
    string title;
    mapping(bytes4 => bool) functions;
    mapping(uint => address) employees;
    uint employeesCount;
  }

  mapping (address => Department) public departments;
  mapping (uint => address) public appointees;
  uint public appointeesCount;
  mapping(uint => mapping(uint => address)) public hierarchy;
  mapping(uint => uint) public levelCount;
  uint public hierarchyDepth;

  event AllowedFunction(address person, string functionName, bool allowed);

  modifier onlyAdmitted() {
    require(msg.sender == owner || msg.sender == DAO || allowedFunction(msg.sender, bytesToBytes4(msg.data)));
    _;
  }

//  modifier onlyDirectors {
//    //only 1st and 0 levels allowed
//    require(departments[msg.sender].exists && departments[msg.sender].level < 2);
//    _;
//  }
  function setDAO(address _DAO) onlyAdmitted public {
    DAO = _DAO;
  }

  function bytesToBytes4(bytes inBytes) internal pure returns (bytes4 outBytes4) {
    if (inBytes.length == 0) { return 0x0; }
    assembly { outBytes4 := mload(add(inBytes, 32)) }
  }

  function isDerector(address sender) public view returns (bool) {
    //only 1st and 0 levels allowed
    return departments[sender].exists && departments[sender].level < 2;
  }
  
  /**
  * Constructor function
  */
  function DAOHierarchy() public {
    Department storage d = departments[msg.sender]; //root
    Employee storage e = employees[msg.sender];

    e.exists = true;
    e.index = employeesCount;
    e.title = "Lord Business";
    e.since = now;
    e.department = msg.sender;

    d.exists = true;
    d.title = "Lord Business Office"; // :)

    d.functions[bytes4(keccak256("setInformation(string)"))] = true;
    // d.functions[bytes4(keccak256("changeVotingRules(uint256,uint256,uint256)"))] = true;
    d.functions[bytes4(keccak256("setAllowedFunction(address,string,bool)"))] = true;

    d.functions[bytes4(keccak256("addDepartment(address,address,string)"))] = true;
    d.functions[bytes4(keccak256("delDepartment(address)"))] = true;
    d.functions[bytes4(keccak256("transferDepartment(address,address)"))] = true;
    d.functions[bytes4(keccak256("addEmployee(address,string,uint256)"))] = true;
    d.functions[bytes4(keccak256("delEmployee(address)"))] = true;
    d.functions[bytes4(keccak256("assignEmployee(address,address)"))] = true;

    employeesList[0] = msg.sender;
    employeesCount++;

    appointees[0] = msg.sender;
    appointeesCount++;

    levelCount[0]++;
    hierarchy[0][0] = msg.sender;

  }

  function setAllowedFunction(address _person, string _function, bool _allowed) onlyAdmitted public  {
    Department storage d = departments[_person];
    require(d.exists);
    d.functions[bytes4(keccak256(_function))] = _allowed;
    emit AllowedFunction(_person, _function, _allowed);
  }

  function checkAllowedFunction(address _person, string _function) public view returns (bool) {
      return allowedFunction(_person, bytes4(keccak256(_function)));
  }
  
  function allowedFunction(address _person, bytes4 _signature) public view returns (bool) {
    Department storage d = departments[_person];
    return d.exists && d.functions[_signature];
  }


  function directorsBoard() public view returns (address[] persons) {
    //1st level of appointees is directors
    persons = new address[](levelCount[1] + 1);
    persons[0] = hierarchy[0][0];
    for(uint i = 0; i < levelCount[1]; i++) {
      persons[i + 1]= hierarchy[1][i];
    }
  }

  function subDepartments(address _person) external view returns(address[] subs) {
    Department storage d = departments[_person];
    subs = new address[](d.subsCount);
    for(uint i = 0; i < d.subsCount; i++) {
      subs[i] = d.subs[i];
    }
  }

  function departmentEmployees(address _person) external view returns(address[] empls) {
    Department storage d = departments[_person];
    empls = new address[](d.employeesCount);
    for(uint i = 0; i < d.employeesCount; i++) {
      empls[i] = d.employees[i];
    }
  }

  function transferDepartment(address _from, address _to) onlyAdmitted public {
    Department storage d = departments[_from];
    Department storage d2 = departments[_to];
    require(d.exists && !d2.exists);
    Employee storage e = employees[_to];
    //copy department
    // d2 = d;
    d2.exists = true;
    d2.level = d.level;
    d2.levelIndex = d.levelIndex;
    d2.subIndex = d.subIndex;
    d2.index = d.index;
    d2.title = d.title;
    d2.subsCount = d.subsCount;
    d2.employeesCount = d.employeesCount;
    d2.head = d.head;
    appointees[d.index] = _to;
    hierarchy[d.level][d.levelIndex] = _to;
    if (d.level > 0) {
      Department storage dh = departments[d.head];
      dh.subs[d.subIndex] = _to;
    }
    for(uint i = 0; i< d.subsCount; i++) {
      d2.subs[i] = d.subs[i];
      departments[d.subs[i]].head = _to;
      delete d.subs[i];
    }
    if (e.department != 0x0) {
      _delFromDepartment(_to);
    }
    for(i = 0; i< d.employeesCount; i++) {
      d2.employees[i] = d.employees[i];
      employees[d.employees[i]].department = _to;
      delete d.employees[i];
    }

    //TODO copy function rights

    delete departments[_from];
    //TODO event
  }

  function addDepartment(address _person, address _head, string _title) onlyAdmitted public {
    //upper dept exists & person not already have department
    require(employees[_person].exists && departments[_head].exists && !departments[_person].exists);
    appointees[appointeesCount] = _person;
    Department storage d = departments[_person];
    d.index = appointeesCount++;
    d.title = _title;
    d.head = _head;
    //calc dept hierarchy level
    address uphead = departments[_head].head;
    uint level = 1;
    while(departments[uphead].exists) {
      level++;
      uphead = departments[uphead].head;
    }
    //в теории level может быть больше hierarchyDepth максимум на 1
    if (level > hierarchyDepth) { hierarchyDepth++; }
    hierarchy[level][levelCount[level]] = _person;
    d.levelIndex = levelCount[level]++;
    d.level = level;
    departments[_head].subs[ departments[_head].subsCount ] = _person;
    d.subIndex = departments[_head].subsCount++;

    //добавляем директора в сотрудники отдела
//   assignEmployee(_person, _person);
    d.exists = true;
    //TODO event
  }

  function delDepartment(address _person) onlyAdmitted public {
    Department storage d = departments[_person];
    //check if no sub dept & not root
    require(d.exists && d.level > 0 && d.subsCount == 0);
    //удаляем из списка подчинений в верхней структуре
    _delFromSub(_person);

    //удаляем из списка иерархии
    address lastInLevel = hierarchy[d.level][--levelCount[d.level]];
    departments[ lastInLevel ].levelIndex = d.levelIndex;
    hierarchy[d.level][d.levelIndex] = lastInLevel;
    delete hierarchy[d.level][levelCount[d.level]];
    if (levelCount[d.level] == 0) { hierarchyDepth--; }

    //удаляем структуру
    _delDepartment(_person);
    //TODO event
  }

  function _delDepartment(address _person) internal {
    address lastAppointee = appointees[--appointeesCount];
    departments[lastAppointee].index = departments[_person].index;
    appointees[departments[_person].index] = lastAppointee;
    delete appointees[appointeesCount];
    delete departments[_person];
  }

  function _delFromSub(address _person) internal {
    Department storage d = departments[_person];
    //удаляем из списка подчинений в верхней структуре
    Department storage dh = departments[d.head];
    address lastInSubs = dh.subs[--dh.subsCount];
    departments[lastInSubs].subIndex = d.subIndex;
    dh.subs[d.subIndex] = lastInSubs;
    delete dh.subs[dh.subsCount];
  }

  //  function incHierarchyDepth() onlyAdmitted public {
  //    ++hierarchyDepth;
  //  }

  //  function decHierarchyDepth() onlyAdmitted public {
  //    require(hierarchyDepth > 0);
  //    for(uint i = 0; i< levelCount[hierarchyDepth]; i++) {
  //      //удаляем каждый отдел в этом уровне
  //      //в теории не должно быть отделов подчиненных удаляемым
  //      _delFromSub(_person);
  //      delete hierarchy[hierarchyDepth][i];
  //      _delDepartment(_person);
  //    }
  //    levelCount[hierarchyDepth--] = 0;
  //  }



  mapping (address => Employee) public employees;
  mapping (uint => address) public employeesList;
  uint public employeesCount;

  struct Employee {
    bool exists;
    uint index;
    address department;
    uint departmentIndex;
    string title;
    uint salary;
    uint since;
  }


  function addEmployee(address _person, string _title, uint _salary) onlyAdmitted public {
    require(!employees[_person].exists);
    Employee storage e = employees[_person];
    e.exists = true;
    e.index = employeesCount;
    e.title = _title;
    e.salary = _salary;
    e.since = now;
    employeesList[employeesCount++] = _person;
  }

  function delEmployee(address _person) onlyAdmitted public {
    Employee storage e = employees[_person];
    require(e.exists && !departments[_person].exists);
    //если уже числится в отделе, то удаляем оттуда
    if (e.department != 0x0) {
      _delFromDepartment(_person);
    }
    address lastEmployee = employeesList[--employeesCount];
    employees[lastEmployee].index = e.index;
    employeesList[e.index] = lastEmployee;
    delete employeesList[appointeesCount];
    delete employees[_person];
  }

  function _delFromDepartment(address _person) internal {
    Employee storage e = employees[_person];
    Department storage d = departments[e.department];
    address lastEmployee = d.employees[--d.employeesCount]; //get last empl. address in list
    employees[lastEmployee].departmentIndex = e.departmentIndex; //change it index in list
    d.employees[e.departmentIndex] = lastEmployee; //place it at this index
    delete d.employees[d.employeesCount]; // and delete last element in list
  }

  function assignEmployee(address _person, address _department) onlyAdmitted public {
    Employee storage e = employees[_person];
    Department storage d = departments[_department];
    require(e.exists && d.exists && !departments[_person].exists);

    //если уже числится в отделе, то удаляем оттуда
    if (e.department != 0x0) {
      _delFromDepartment(_person);
    }
    d.employees[d.employeesCount] = _person;
    e.department = _department;
    e.departmentIndex = d.employeesCount++;
  }

}


/**
 * The shareholder association contract itself
 */
contract DAO is Ownable {//tokenRecipient
  address public newDAO; //if =0 assuming this is last dao contract
  string public information; // info
  
  
  struct Vote {
    bool decision;
    address voter;
  }

  struct Proposal {
    bool general;
    address recipient;
    uint value;
    string description;
    uint startedAt;
    bool executed;
    bool proposalPassed;
    uint numberOfVotes;
    //    bytes32 proposalHash;
    bytes byteCode;
    Vote[] votes;
    mapping(address => bool) voted;
  }

  uint public passPercent; // Количество процентов для принятия инициативы
  uint public minForceAmount; // Количество токенов для того, чтобы выдвигать предложения
  uint public minTime; // min time for waiting proposal voters

  uint public curProposalId;
  Proposal[] public proposals;
  
  DAOHierarchy public daoHierarchy;
  ForceToken public forceToken;
  ForceSeller public forceSeller;

  //  enum InternalProposalsType { NEW_DAO, DUST_DISTRIBUTION, ETHER_DISTRIBUTION }

  event ProposalAdded(uint proposalId, address recipient, uint amount, string description);
  event Voted(uint proposalId, bool position, address voter);
  event ProposalTallied(uint proposalId, bool passed, uint pros, uint cons, uint total);
  //  event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriod, address newSharesTokenAddress);
  event ChangeOfRules(uint minDebatingPeriod, uint percentForExecute, uint forceAmountForNewProposals);
  event NewDAO(address newDAOAddress);
  event NewOwner(address newOwnerAddress);
    event Withdrawal(uint value);

  modifier onlyAdmitted() {
    require(msg.sender == owner || msg.sender == address(this) || daoHierarchy.allowedFunction(msg.sender, bytesToBytes4(msg.data)));
    _;
  }
  modifier onlyLastDAO {
    require(newDAO == 0x0);
    _;
  }

  function bytesToBytes4(bytes inBytes) internal pure returns (bytes4 outBytes4) {
    if (inBytes.length == 0) { return 0x0; }
    assembly { outBytes4 := mload(add(inBytes, 32)) }
  }

  /**
   * Constructor function
   *
   * First time setup
   */
  function DAO(address _forceTokenAddress, address _forceSellerAddress, address _daoHierarchy) public {
    // owner = this; //set DAO to self owner
    forceToken = ForceToken(_forceTokenAddress);
    forceSeller = ForceSeller(_forceSellerAddress);
    daoHierarchy = DAOHierarchy(_daoHierarchy);
    changeVotingRules(1, 60, 1000000);
    owner = this;
  }

  function setInformation(string _information) onlyAdmitted public {
    information = _information;
  }
  /**
   * Change voting rules
   *
   * Make so that proposals need to be discussed for at least `minutesForDebate/60` hours
   * and all voters combined must own more than `minimumSharesToPassAVote` shares of token `sharesAddress` to be executed
   *
   */
  //todo добавить таймы голосования
  //    address _forceTokenAddress, uint _minimumQuorum, uint _debatingPeriod
  function changeVotingRules(uint _minTime, uint _passPercent, uint _minForceAmount) onlyAdmitted onlyLastDAO public {
    minTime = _minTime;
    passPercent = _passPercent;
    minForceAmount = _minForceAmount;
    emit ChangeOfRules(_minTime, _passPercent, _minForceAmount);
  }

  /**
   * Add Proposal
   *
   * Propose to send `_value` ether to `_recipient` for `_description`.
   * `_byteCode ? Contains : Does not contain` transaction bytecode.
   *
   * @param _recipient who to send the ether to
   * @param _value amount of ether to send, in wei
   * @param _description Description of job
   * @param _byteCode bytecode of transaction
   */
  function newProposal(address _recipient, uint _value, string _description, bool _general, bytes _byteCode) onlyLastDAO public returns (uint proposalId)
  {
    require(forceToken.balanceOf(msg.sender) > minForceAmount);
    curProposalId = proposals.length++;
    Proposal storage p = proposals[curProposalId];
    p.general = _general;
    p.recipient = _recipient;
    p.value = _value;
    p.description = _description;
    p.byteCode = _byteCode;
    //    p.proposalHash = keccak256(_recipient, _value, _byteCode);
    p.startedAt = now;
    // p.executed = false;
    // p.proposalPassed = false;
    // p.numberOfVotes = 0;
    emit ProposalAdded(curProposalId, _recipient, _value, _description);
    return curProposalId;
  }


  /**
   * Log a vote for a proposal
   *
   * Vote `_decision? in support of : against` proposal #`_proposalId`
   *
   * @param _proposalId number of proposal
   * @param _decision either in favor or against it
   */
  function vote(uint _proposalId, bool _decision) onlyLastDAO public returns (uint voteId)
  {
    require(forceToken.balanceOf(msg.sender) > minForceAmount);
    Proposal storage p = proposals[_proposalId];
    require(!p.executed);
    require(p.voted[msg.sender] != true);
    if (!p.general) {
      require(daoHierarchy.isDerector(msg.sender));
    }

    voteId = p.votes.length++;
    p.votes[voteId] = Vote({decision : _decision, voter : msg.sender});
    p.voted[msg.sender] = true;
    p.numberOfVotes = voteId + 1;
    emit Voted(_proposalId, _decision, msg.sender);

    // If you can execute it now, do it
    //    if ( now > proposalDeadline(proposalNumber)
    //      && p.currentResult > 0
    //      && p.proposalHash == sha3(p.recipient, p.amount, '')
    //      && supportsProposal) {
    //        executeProposal(proposalNumber, '');
    //    }
    return voteId;
  }

  //  function proposalDeadline(uint _proposalId) constant returns (uint deadline) {
  //    Proposal storage p = proposals[_proposalId];
  //    uint factor = calculateFactor(uint(p.currentResult), (directors.length - 1));
  //    return p.creationDate + uint(factor * minimumTime * 1 minutes);
  //  }

  function calculateFactor(uint a, uint b) internal pure returns (uint factor) {
    return 2 ** (20 - (20 * a) / b);
  }

  function proposalVotes(uint _proposalId, uint _voteId) public view returns (address voter, bool decision) {
    Proposal storage p = proposals[_proposalId];
    Vote storage v = p.votes[_voteId];
    return (v.voter, v.decision);
  }

  function proposalStatus(uint _id) public view returns(bool active, uint curQuorum, uint ownedTokens, uint timeToExecute) {
    Proposal storage p = proposals[_id];
    // active = !p.executed;
    // curQuorum = 0;
    for (uint i = 0; i < p.votes.length; ++i) {
      Vote storage v = p.votes[i];
      curQuorum += forceToken.balanceOf(v.voter);
    }
    if (p.general) {
      ownedTokens = forceToken.totalSupply() - forceToken.balanceOf(forceToken) - forceToken.balanceOf(forceSeller);
    } else {
      ownedTokens = forceToken.balanceOf(daoHierarchy.hierarchy(0, 0));
      for(i = 0; i < daoHierarchy.levelCount(1); i++) {
        ownedTokens += forceToken.balanceOf(daoHierarchy.hierarchy(1, i));
      }
    }
    // Check if a minimum quorum has been reached
    uint factor = calculateFactor(curQuorum, ownedTokens);
    uint endAt = p.startedAt + (factor * minTime * 1 minutes);
    // timeToExecute = endAt > now ? endAt - now : 0;
    return(!p.executed, curQuorum, ownedTokens, endAt > now ? endAt - now : 0);
  }

  /**
   * Finish vote
   *
   * Count the votes proposal #`_proposalId` and execute it if approved
   *
   * @param _proposalId proposal number
   */
  function executeProposal(uint _proposalId) onlyLastDAO public {
    Proposal storage p = proposals[_proposalId];
    require(!p.executed);
    uint pros = 0;
    uint cons = 0;
    uint ownedTokens;

    for (uint i = 0; i < p.votes.length; ++i) {
      Vote storage v = p.votes[i];
      uint voteWeight = forceToken.balanceOf(v.voter);
      if (v.decision) {
        pros += voteWeight;
      } else {
        cons += voteWeight;
      }
    }
    uint quorum = pros + cons;

    if (p.general) {
      ownedTokens = forceToken.totalSupply() - forceToken.balanceOf(forceToken) - forceToken.balanceOf(forceSeller);
    } else {
       ownedTokens = forceToken.balanceOf(daoHierarchy.hierarchy(0, 0));
      for(i = 0; i < daoHierarchy.levelCount(1); i++) {
        ownedTokens += forceToken.balanceOf(daoHierarchy.hierarchy(1, i));
      }
    }

    // Check if a minimum quorum has been reached
    uint factor = calculateFactor(quorum, ownedTokens);
    require(now > p.startedAt + uint(factor * minTime * 1 minutes));

    if (pros * 100 / quorum > passPercent) {
      // Proposal passed; execute the transaction
      p.executed = true;
      require(p.recipient.call.value(p.value)(p.byteCode));
      p.proposalPassed = true;
    } else {
      // Proposal failed
      p.proposalPassed = false;
    }

    // Fire Events
    emit ProposalTallied(_proposalId, p.proposalPassed, pros, cons, ownedTokens);
  }

  function setForceSeller(address _forceSellerAddress) onlyAdmitted public {
    forceSeller = ForceSeller(_forceSellerAddress);
  }

  function setForcetoken(address _forceTokenAddress) onlyAdmitted public {
    forceToken = ForceToken(_forceTokenAddress);
  }

//todo delete
    function setHyerarchy(address _daoHierarchy) onlyAdmitted public  {
        daoHierarchy = DAOHierarchy(_daoHierarchy);
    }
    

    // withdraw available funds from contract
    function withdrawFunds(address _to, uint _value) onlyAdmitted public {
        require(address(this).balance >= _value);
        _to.transfer(_value);
        emit Withdrawal(_value);
    }
    
  function setNewDao(address _DAOAddress) onlyAdmitted public {
    require(_DAOAddress != address(0));
    newDAO = _DAOAddress;
    forceToken.setDAO(_DAOAddress);
    if (forceToken.owner() == address(this)) {
        forceToken.transferOwnership(_DAOAddress);
    }
    forceSeller.setDAO(_DAOAddress);
    if (forceSeller.owner() == address(this)) {
        forceSeller.transferOwnership(_DAOAddress);
    }
    daoHierarchy.setDAO(_DAOAddress);
    if (daoHierarchy.owner() == address(this)) {
        daoHierarchy.transferOwnership(_DAOAddress);
    }
    emit NewDAO(_DAOAddress);
  }
  
  function setNewOwner(address _owner) onlyOwner public {
    if (forceToken.owner() == address(this)) {
        forceToken.transferOwnership(_owner);
    }
    if (forceSeller.owner() == address(this)) {
        forceSeller.transferOwnership(_owner);
    }
    if (daoHierarchy.owner() == address(this)) {
        daoHierarchy.transferOwnership(_owner);
    }
    transferOwnership(_owner);
    emit NewOwner(_owner);
  }


//   function getByteCode(string f, uint[] d) internal pure returns (bytes byteCode) {
//     byteCode = new bytes(d.length * 32 + 4);
//     bytes4 h = bytes4(keccak256(f));
//     uint l;
//     uint i;
//     uint j;
//     for (i = 0; i < 4; i++) {byteCode[l++] = h[i];}
//     bytes32 tmp;
//     for (i = 0; i < d.length; i++) {
//       tmp = bytes32(d[i]);
//       for (j = 0; j < 32; j++) {byteCode[l++] = tmp[j];}
//     }
//   }

  //internal proposals
  function startNewDaoProposal(address _DAOAddress) public returns (uint){
    return prepareProposal("setNewDao(address)", "Set new DAO contract", false, msg.data);
    _DAOAddress;
  }

  function startNewOwnerProposal(address _newOwner) public returns (uint){
    return prepareProposal("setNewOwner(address)", "Set new owner", true, msg.data);
    _newOwner;
  }

  function startWithdrawalProposal(address _to, uint _value) public returns (uint){
      bytes memory e;
    return newProposal(_to, _value, "Withdrawal from DAO", false, e);
  }
  
  function prepareProposal(string f, string c, bool g, bytes d) internal returns (uint) {
    bytes4 h = bytes4(keccak256(f));
    d[0] = h[0];
    d[1] = h[1];
    d[2] = h[2];
    d[3] = h[3];
    return newProposal(address(this), 0, c, g, d);
      
  }

}