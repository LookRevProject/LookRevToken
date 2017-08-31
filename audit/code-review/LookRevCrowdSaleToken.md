# LookRevToken

Source file [../../LookRevToken.sol](../../LookRevToken.sol)

First review commit [5761ecf1](https://github.com/LookRevTeam/LookRevToken/blob/5761ecf12e965af0a5b21caee9964e36b9b10466/LookRevCrowdSaleToken.sol).

Second review commit [2ce6918c](https://github.com/LookRevTeam/LookRevToken/blob/2ce6918c3b06b088338428c5a6ad39a0971ffe58/LookRevCrowdSaleToken.sol).

Third review commit [e708b6c0](https://github.com/LookRevTeam/LookRevToken/blob/e708b6c01ad6514c7b212b91c39fa0f28b98b3bc/LookRevCrowdSaleToken.sol).

Fourth review commit [c0e67cf1](https://github.com/LookRevTeam/LookRevToken/blob/c0e67cf1d9cb93b40d7aa930256723ab36a6598b/LookRevCrowdSaleToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;

/*
* LOK 'LookRev Token' crowdfunding contract
*
* Refer to https://lookrev.com/ for further information.
* 
* Developer: LookRev (TM) 2017.
*
* Audited by BokkyPooBah / Bok Consulting Pty Ltd 2017.
* 
* The MIT License.
*
*/

/*
 * ERC20 Token Standard
 * https://github.com/ethereum/EIPs/issues/20
 *
 */
 // BK Ok
contract ERC20 {
  // BK Ok
  uint public totalSupply;
  // BK Ok
  function balanceOf(address _who) constant returns (uint balance);
  // BK Ok
  function allowance(address _owner, address _spender) constant returns (uint remaining);

  // BK Ok
  function transfer(address _to, uint _value) returns (bool ok);
  // BK Ok
  function transferFrom(address _from, address _to, uint _value) returns (bool ok);
  // BK Ok
  function approve(address _spender, uint _value) returns (bool ok);
  // BK Ok
  event Transfer(address indexed _from, address indexed _to, uint _value);
  // BK Ok
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * Math operations with safety checks
 */
// BK Ok
contract SafeMath {
  // BK Ok
  function safeAdd(uint a, uint b) internal returns (uint) {
    // BK Ok
    uint c = a + b;
    // BK Ok
    assert(c >= a && c >= b);
    // BK Ok
    return c;
  }

  // BK Ok
  function safeSub(uint a, uint b) internal returns (uint) {
    // BK Ok
    assert(b <= a);
    // BK Ok
    uint c = a - b;
    // BK Ok
    assert(c <= a);
    // BK Ok
    return c;
  }
}

// BK Ok
contract Ownable {
  // BK Ok
  address public owner;
  // BK Ok
  address public newOwner;

  // BK Ok - Constructor
  function Ownable() {
    // BK Ok
    owner = msg.sender;
  }

  // BK Ok
  modifier onlyOwner {
    // BK Ok
    require(msg.sender == owner);
    // BK Ok
    _;
  }

  // BK Ok
  function transferOwnership(address _newOwner) onlyOwner {
    // BK Ok
    if (_newOwner != address(0)) {
      // BK Ok
      newOwner = _newOwner;
    }
  }

  // BK Ok
  function acceptOwnership() {
    // BK Ok
    require(msg.sender == newOwner);
    // BK Ok
    OwnershipTransferred(owner, newOwner);
    // BK Ok
    owner = newOwner;
  }
  // BK Ok
  event OwnershipTransferred(address indexed _from, address indexed _to);
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by InvestSeed
 */
// BK Ok
contract StandardToken is ERC20, Ownable, SafeMath {

    // BK Ok
    mapping (address => uint) balances;
    // BK Ok
    mapping (address => mapping (address => uint)) allowed;

    // BK Ok
    function balanceOf(address _owner) constant returns (uint balance) {
        // BK Ok
        return balances[_owner];
    }

    // BK Ok
    function transfer(address _to, uint _amount) returns (bool success) {
        // avoid wasting gas on 0 token transfers
        // BK Ok
        if(_amount == 0) return true;

        // BK Ok - Account has balance to transfer
        if (balances[msg.sender] >= _amount
            // BK Ok - Transferring non-zero amount
            && _amount > 0
            // BK Ok - Overflow check
            && balances[_to] + _amount > balances[_to]) {
            // BK Ok
            balances[msg.sender] = safeSub(balances[msg.sender],_amount);
            // BK Ok
            balances[_to] = safeAdd(balances[_to],_amount);
            // BK Ok
            Transfer(msg.sender, _to, _amount);
            // BK Ok
            return true;
        // BK Ok
        } else {
            // BK Ok
            return false;
        }
    }

    // BK Ok
    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
        // avoid wasting gas on 0 token transfers
        // BK Ok
        if(_amount == 0) return true;

        // BK Ok - Account has balance to transfer
        if (balances[_from] >= _amount
            // BK Ok - Was previously `&& allowed[_from][_to] >= _amount`
            && allowed[_from][msg.sender] >= _amount
            // BK Ok - Transferring non-zero amount
            && _amount > 0
            // BK Ok - Overflow check
            && balances[_to] + _amount > balances[_to]) {
            // BK Ok
            balances[_from] = safeSub(balances[_from],_amount);
            // BK Ok - Was previously `allowed[_from][_to] = safeSub(allowed[_from][_to],_amount);`
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);
            // BK Ok
            balances[_to] = safeAdd(balances[_to],_amount);
            // BK Ok
            Transfer(_from, _to, _amount);
            // BK Ok
            return true;
        // BK Ok
        } else {
            // BK Ok
            return false;
        }
    }

    // BK Ok
    function approve(address _spender, uint _value) returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        // BK NOTE - `(_value != 0) && (allowed[msg.sender][_spender] != 0)` is the same as
        // BK NOTE - `!((_value == 0) || (allowed[msg.sender][_spender] == 0))`
        // BK Ok
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
           // BK Ok
           return false;
        }
        // BK Ok - Check approved amount is more than the account balance
        if (balances[msg.sender] < _value) {
            // BK Ok
            return false;
        }
        // BK Ok
        allowed[msg.sender][_spender] = _value;
        // BK Ok
        Approval(msg.sender, _spender, _value);
        // BK Ok
        return true;
     }

     // BK Ok
     function allowance(address _owner, address _spender) constant returns (uint remaining) {
       // BK Ok
       return allowed[_owner][_spender];
     }
}

/**
 * LookRev token initial offering.
 *
 * Token supply is created in the token contract creation and allocated to owner.
 *
 */
// BK Ok
contract LookRevToken is StandardToken {

    /*
    *  Token meta data
    */
    // BK Ok
    string public constant name = "LookRev";
    // BK Ok
    string public constant symbol = "LOK";
    // BK Ok
    uint8 public constant decimals = 18;
    // BK Ok
    string public VERSION = 'LOK1.0';
    // BK Ok
    bool public finalised = false;
    
    // BK Ok
    address public wallet = 0x0;

    // BK Ok
    mapping(address => bool) public kycRequired;

    // Start - Friday, September 8, 2017 3:00:00 PM (8:00:00 AM GMT-07:00 DST)
    // BK Ok - new Date(1504882800 * 1000).toUTCString() => "Fri, 08 Sep 2017 15:00:00 UTC"
    uint public constant START_DATE = 1504882800;
    // 3000 LOK Per ETH for the 1st 24 Hours - Till Saturday, September 9, 2017 3:00:00 PM UTC (8:00:00 AM GMT-07:00 DST)
    // BK Ok - new Date(1504969200 * 1000).toUTCString() => "Sat, 09 Sep 2017 15:00:00 UTC"
    uint public constant BONUSONE_DATE = 1504969200;
    // 2700 LOK Per ETH for the Next 48 Hours - Till Monday, September 11, 2017 3:00:00 PM (8:00:00 AM GMT-07:00 DST)
    // BK Ok - new Date(1505142000 * 1000).toUTCString() => "Mon, 11 Sep 2017 15:00:00 UTC"
    uint public constant BONUSTWO_DATE = 1505142000;
    // Regular Rate - 2400 LOK Per ETH for the Remaining Part of the Crowdsale
    // End - Sunday, October 8, 2017 3:00:00 PM (8:00:00 AM GMT-07:00 DST)
    // BK Ok - new Date(1507474800 * 1000).toUTCString() => "Sun, 08 Oct 2017 15:00:00 UTC"
    uint public constant END_DATE = 1507474800;

    // BK Ok
    uint public constant DECIMALSFACTOR = 10**uint(decimals);
    // BK Ok - 10,000,000
    uint public constant TOKENS_SOFT_CAP =   10000000 * DECIMALSFACTOR;
    // BK Ok - 2,000,000,000
    uint public constant TOKENS_HARD_CAP = 2000000000 * DECIMALSFACTOR;
    // BK Ok - 5,000,000,000
    uint public constant TOKENS_TOTAL =    5000000000 * DECIMALSFACTOR;
    // BK Ok
    uint public constant INITIAL_SUPPLY = 10000000 * DECIMALSFACTOR;

    // 1 KETHER = 2,400,000 tokens
    // 1 ETH = 2,400 tokens
    // BK NOTE - This assignment is overridden in the proxyPayment(...) function
    // BK Ok
    uint public tokensPerKEther = 2400000;
    // BK Ok
    uint public CONTRIBUTIONS_MIN = 0 ether;
    // BK Ok
    uint public CONTRIBUTIONS_MAX = 0 ether;
    // BK Ok - KYC threshold 100 ETH
    uint public constant KYC_THRESHOLD = 100 * DECIMALSFACTOR;

    // BK Ok - Constructor
    function LookRevToken() {
      // BK Ok - This is not required as it is set in the Ownable constructor
      owner = msg.sender;
      // BK Ok
      wallet = owner;
      // BK Ok
      totalSupply = INITIAL_SUPPLY;
      // BK Ok
      balances[owner] = totalSupply;
    }

   // LookRev can change the crowdsale wallet address
   // BK Ok - Owner can change the wallet address at any time
   function setWallet(address _wallet) onlyOwner {
        // BK Ok
        wallet = _wallet;
        // BK Ok
        WalletUpdated(wallet);
    }
    // BK Ok
    event WalletUpdated(address newWallet);

    // Can only be set before the start of the crowdsale
    // Owner can change the rate before the crowdsale starts
    // BK NOTE - This assignment is overridden in the proxyPayment(...) function and this function is obsolete
    // BK Ok
    function setTokensPerKEther(uint _tokensPerKEther) onlyOwner {
        // BK Ok
        require(now < START_DATE);
        // BK Ok
        require(_tokensPerKEther > 0);
        // BK Ok
        tokensPerKEther = _tokensPerKEther;
        // BK Ok
        TokensPerKEtherUpdated(tokensPerKEther);
    }
    // BK Ok
    event TokensPerKEtherUpdated(uint tokensPerKEther);

    // Accept ethers to buy tokens during the crowdsale
    // BK Ok
    function () payable {
        // BK Ok
        proxyPayment(msg.sender);
    }

    // Accept ethers and exchanges to purchase tokens on behalf of user
    // msg.value (in units of wei)
    // BK Ok - Any account can contribute ethers for tokens in return when the crowdsale is active
    function proxyPayment(address participant) payable {

        // BK Ok
        require(!finalised);

        // BK Ok
        require(now <= END_DATE);

        // BK Ok
        require(msg.value > CONTRIBUTIONS_MIN);
        // BK Ok - Could be `<=` instead of `<`
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

         // Add in bonus during the first 24 and 48 hours of the token sale
         // BK Ok
         if (now < START_DATE) {
            tokensPerKEther = 2400000;
         } else if (now < BONUSONE_DATE) {
            tokensPerKEther = 3000000;
         } else if (now < BONUSTWO_DATE) {
            tokensPerKEther = 2700000;
         } else {
            tokensPerKEther = 2400000;
         }

         // Calculate number of tokens for contributed ETH
         // `18` is the ETH decimals
         // `- decimals` is the token decimals
         // BK Ok
         uint tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

         // Check if the hard cap will be exceeded
         // BK Ok
         require(totalSupply + tokens <= TOKENS_HARD_CAP);

         // Add tokens purchased to account's balance and total supply
         // BK Ok
         balances[participant] = safeAdd(balances[participant],tokens);
         // BK Ok
         totalSupply = safeAdd(totalSupply,tokens);

         // Log the tokens purchased 
         // BK Ok 
         Transfer(0x0, participant, tokens);
         // - buyer = participant
         // - ethers = msg.value
         // - participantTokenBalance = balances[participant]
         // - tokens = tokens
         // - newTotalSupply = totalSupply
         // - tokensPerKEther = tokensPerKEther
         TokensBought(participant, msg.value, balances[participant], tokens,
              totalSupply, tokensPerKEther);

         if (msg.value > KYC_THRESHOLD) {
             // KYC verification required before participant can transfer the tokens
             // BK Ok
             kycRequired[participant] = true;
         }

         // Transfer the contributed ethers to the crowdsale wallet
         // BK Ok
         // throw is deprecated starting from Ethereum v0.9.0
         wallet.transfer(msg.value);
    }

    // BK Ok - Old `newEtherBalance` has now been renamed to `participantTokenBalance`
    event TokensBought(address indexed buyer, uint ethers, 
        uint participantTokenBalance, uint tokens, uint newTotalSupply, 
        uint tokensPerKEther);

    // BK Ok - Only the owner can finalise, if soft cap reached or after the crowdsale end
    function finalise() onlyOwner {
        // Can only finalise if raised > soft cap or after the end date
        // BK Ok
        require(totalSupply >= TOKENS_SOFT_CAP || now > END_DATE);

        // BK Ok - Cannot finalise more than once
        require(!finalised);

        // BK Ok
        finalised = true;
    }

    // BK Ok - Only owner
   function addPrecommitment(address participant, uint balance) onlyOwner {
        // BK Ok
        require(now < START_DATE);
        // BK Ok
        require(balance > 0);
        // BK Ok
        balances[participant] = safeAdd(balances[participant],balance);
        // BK Ok
        totalSupply = safeAdd(totalSupply,balance);
        // BK Ok
        Transfer(0x0, participant, balance);
        // BK Ok
        PrecommitmentAdded(participant, balance);
    }
    // BK Ok
    event PrecommitmentAdded(address indexed participant, uint balance);

    // BK Ok
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends
        // Allow awarding team members before, during and after crowdsale
        // BK Ok
        require(finalised || msg.sender == owner);
        // BK Ok
        require(!kycRequired[msg.sender]);
        // BK Ok
        return super.transfer(_to, _amount);
    }

   // BK Ok
   function transferFrom(address _from, address _to, uint _amount) returns (bool success)
    {
        // Cannot transfer before crowdsale ends
        // BK Ok
        require(finalised);
        // BK Ok
        require(!kycRequired[_from]);
        // BK Ok
        return super.transferFrom(_from, _to, _amount);
    }

    // BK Ok - Only owner
    function kycVerify(address participant, bool _required) onlyOwner {
        // BK Ok
        kycRequired[participant] = _required;
        // BK Ok
        KycVerified(participant, kycRequired[participant]);
    }
    // BK Ok
    event KycVerified(address indexed participant, bool required);

    // Any account can burn _from's tokens as long as the _from account has
    // approved the _amount to be burnt using approve(0x0, _amount)
    // BK Ok - Anyone can burn tokens that have been approved for burning
    function burnFrom(address _from, uint _amount) returns (bool success) {
        // BK Ok - Cannot burn more than total supply
        require(totalSupply >= _amount);

        // BK Ok - Cannot burn more tokens than the token balance 
        if (balances[_from] >= _amount
            // BK Ok - Cannot burn more tokens that the tokens approved for burning
            && allowed[_from][0x0] >= _amount
            // BK Ok - Amount must be non-zero
            && _amount > 0
            // BK Ok - Adding burnt tokens to the 0x0 account - check for overflow
            && balances[0x0] + _amount > balances[0x0]
        ) {
            // BK Ok
            balances[_from] = safeSub(balances[_from],_amount);
            // BK Ok
            balances[0x0] = safeAdd(balances[0x0],_amount);
            // BK Ok
            allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);
            // BK Ok
            totalSupply = safeSub(totalSupply,_amount);
            // BK Ok - Log event
            Transfer(_from, 0x0, _amount);
            // BK Ok
            return true;
        // BK Ok
        } else {
            // BK Ok
            return false;
        }
    }

    // LookRev can transfer out any accidentally sent ERC20 tokens
    // BK Ok
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) 
    {
        // BK Ok
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}
```