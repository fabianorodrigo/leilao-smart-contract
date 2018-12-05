pragma solidity ^0.4.17;
// import "github.com/ethereum/dapp-bin/library/stringUtils.sol";

contract MusicRegistration {
    address public publishPerson;
    string public  songTitle;
    string public hashOfSong;
    string public artistName;
    string public artistID;
    string public ownerName;
    string public otherOwner;
    string public DigitalSingature;
    address[] public arrLisenced;
    
    function  MusicRegistration( string sTitle, string sHash,
        string sOwnerName, string oDigital, string aName, string oOwner, string artID) public{
        publishPerson = msg.sender;
        songTitle = sTitle;
        hashOfSong = sHash;
        artistName = aName;
        ownerName = sOwnerName;
        otherOwner = oOwner;
        DigitalSingature = oDigital;
        artistID = artID;
    }
    
    function getPublishPerson() external constant returns (address addr){
        addr = publishPerson;
    }
    
    function getMusicRegistration() external constant returns(string sTitle, 
    string sHash, string oName, string oDigital, string aName, string artID, string oOwner){
        sTitle = songTitle;
        sHash = hashOfSong;
        aName = artistName;
        oName = ownerName;
        artID = artistID;
        oOwner = otherOwner;
        oDigital = DigitalSingature;
    }
    
    function insertLicensed(address licensedAddress) public returns (bool){
        for(uint i=0; i < arrLisenced.length; i++){
            if(arrLisenced[i] == licensedAddress){
                return false;
            }
        }
        arrLisenced.push(licensedAddress);
        return true;
    }
    
    function getAllLicensed()external constant returns (address[] arrResult){
        arrResult = arrLisenced;
    }
    
    function getContractAddress() external constant returns (address){
        return this;
    }
}

contract MusicLicensed {
    enum LicensedState { Pending, Expired , Licensed }
    address  buyAddress;
    address  songAddress;
    string  licenseTo;
    string  songTitle;
    string  territories;
    string  songRight;
    uint  period;
    uint256 startTime; // start time will be the time we create contract. Default Expired date will be 2 days
    bool  isCompleted;
    uint priceLicensed;
    
    // function MusicLicensed() public{
        
    // }

    function MusicLicensed(address sAddress, string licenseToUser,
        string sTitle, string ter, string right, uint periodLicense
        ) public{
        buyAddress = msg.sender;
        songAddress = sAddress;
        licenseTo = licenseToUser;
        songTitle = sTitle;
        territories = ter;
        songRight = right;
        period = periodLicense;
        isCompleted = false;
        startTime = block.timestamp;
        MusicRegistration musicToken = MusicRegistration (songAddress);
        musicToken.insertLicensed(address(this));
    }
    
    function getStatus() private returns (LicensedState state){
        if(isCompleted == true){
            state = LicensedState.Licensed;
        }else {
            if((startTime - block.timestamp)> 2 days){
                state = LicensedState.Expired;
            }else{
                state = LicensedState.Pending;
            }
        }
    }
    
    function getContractStatus() public returns (string){
        LicensedState currentState = getStatus();
        if(currentState == LicensedState.Pending){
            return "Pending";
        }else if(currentState == LicensedState.Expired){
            return "Expired";
        }else {
            return "Licensed";
        }
    }
    
    function getLicensed() external constant returns (address sAddress,
        string licenseToUser, string sTitle, string ter, string right, 
        uint periodLicense, string state){
        sAddress = songAddress;
        licenseToUser = licenseTo;
        sTitle = songTitle;
        ter = territories;
        right = songRight;
        periodLicense = period;
        LicensedState currentState = getStatus();
        if(currentState == LicensedState.Pending){
            state  = "Pending";
        }else if(currentState == LicensedState.Expired){
            state = "Expired";
        }else {
            state = "Licensed";
        }
    }
    
    function updatePrice(uint amount) public{
        MusicRegistration musicToken = MusicRegistration (songAddress);
        require(musicToken.getPublishPerson() != address(0));
        require(musicToken.getPublishPerson() == msg.sender);
        require (amount >0);
        priceLicensed = amount;
    }
    
    function verifyAndConfirm() public {
        MusicRegistration musicToken = MusicRegistration (songAddress);
        require(musicToken.getPublishPerson() != address(0));
        require(musicToken.getPublishPerson() == msg.sender);
        isCompleted = true;
    }
    
    function getContractAddress() external constant returns (address){
        return this;
    }
}