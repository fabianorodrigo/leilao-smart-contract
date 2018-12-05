pragma solidity ^0.4.18;

contract Procurement {
    
    modifier restrictToAdmin {
        if (msg.sender == admin) _;
        else revert();
    }
    
    // keep track of whether the procurement is ongoing
    bool public ongoing;
    
    // keep track of the amount of revisions entered by each provider
    // this is used to map the current revision to the correct hash
    int8 public revisionCountProviderA;
    int8 public revisionCountProviderB;
    
    // keep a mapping of the revision hash at that revision number for each provider
    mapping (int8 => string) public revisionsProviderA;
    mapping (int8 => string) public revisionsProviderB;
    
    // keep a mapping of the score at that revision number for each provider
    int8 public scoreProviderA;
    int8 public scoreProviderB;
    
    address public admin;
    address public providerA;
    address public providerB;
    
    // creator is the admin and the owner of the contract
    constructor () public {
        admin = msg.sender;
        ongoing = true;
    }
    
    // Kill contract and return funds to owner (can only be executed by owner)
    function kill() restrictToAdmin public {
        selfdestruct(admin);
    }

    // Change admin to new address
    function chown(address _addr) restrictToAdmin public {
        admin = _addr;
    }
    
    // end the procurement
    // this prevents providers from entering new revisions and allows getting the winner
    function finish() restrictToAdmin public {
        ongoing = false;
    }
    
    function getProviderARevisionCount() restrictToAdmin public view returns (int8) {
        return revisionCountProviderA;
    }
    
    function getProviderBRevisionCount() restrictToAdmin public view returns (int8) {
        return revisionCountProviderB;
    }
    
    
    function isOngoing() restrictToAdmin public view returns (bool) {
        return ongoing;
    }
    
    function setProviderA (address _addr) restrictToAdmin public {
        providerA = _addr;
    }
    
    function setProviderB (address _addr) restrictToAdmin public {
        providerB = _addr;
    }
    
    function getProviderA () restrictToAdmin public view returns (address) {
        return providerA;
    }
    
    function getProviderB () restrictToAdmin public view returns (address) {
        return providerB;
    }
    
    function getAdmin() restrictToAdmin public view returns (address) {
        return admin;
    }
    
    // enter the score for provider A at the current revision number
    function setScoreProviderA (int8 _score) restrictToAdmin public {
        if (!ongoing) {
            scoreProviderA = _score;
        }
    }
    
    // enter the score for provider B at the current revision number
    function setScoreProviderB (int8 _score) restrictToAdmin public {
        if (!ongoing) {
            scoreProviderB = _score;
        }
    }
    
    // get the score for provider A at the current revision number
    function getScoreProviderA () restrictToAdmin public view returns (int8) {
        return scoreProviderA;
    }
    
    // get the score for provider B at the current revision number
    function getScoreProviderB () restrictToAdmin public view returns (int8) {
        return scoreProviderB;
    }
    
    // get the winner if the procurement is over
    function getWinner() restrictToAdmin public view returns (string) {
        if (ongoing) {
            return "procurement still ongoing!";
        } else {
            if (scoreProviderA == 0 && scoreProviderB == 0) {
                return "both providers have 0 score";
            } else if (scoreProviderA > scoreProviderB) {
                return "providerA";
            } else if (scoreProviderA < scoreProviderB) {
                return "providerB";
            } else {
                return "tie";
            }
        }
    }
    
    // allow provider A to submit a new revision if the procurement is ongoing
    function updateRevisionProviderA (string _revisionHash) restrictToAdmin public {
        if (ongoing) {
            // increase the revision count to make sure we're submitting correctly and scoring correctly
            revisionCountProviderA += 1;
            revisionsProviderA[revisionCountProviderA] = _revisionHash;
        } 
        // else {
            // revert();
        // }
    }
    
    // allow provider B to submit a new revision if the procurement is ongoing
    function updateRevisionProviderB (string _revisionHash) restrictToAdmin public {
        if (ongoing) {
            // increase the revision count to make sure we're submitting correctly and scoring correctly
            revisionCountProviderB += 1;
            revisionsProviderB[revisionCountProviderB] = _revisionHash;
        }
        // } else {
            // revert();
        // }
    }
    
    function getCurrentRevisionProviderA () restrictToAdmin public view returns (string){
        return revisionsProviderA[revisionCountProviderA];
    }
    
    function getCurrentRevisionProviderB () restrictToAdmin public view returns (string){
        return revisionsProviderB[revisionCountProviderB];
    }
    
    // for debugging, reset the contract to it's default state
    function reset() restrictToAdmin public {
        for (int8 indexA = 0; indexA < revisionCountProviderA; indexA++) {
            delete revisionsProviderA[indexA];
        }
        
        for (int8 indexB = 0; indexB < revisionCountProviderB; indexB++) {
            delete revisionsProviderB[indexB];
        }
        
        revisionCountProviderA = 0;
        revisionCountProviderB = 0;
        scoreProviderA = 0;
        scoreProviderB = 0;
        delete providerA;
        delete providerB;
        
        ongoing = true;
    }
    
}