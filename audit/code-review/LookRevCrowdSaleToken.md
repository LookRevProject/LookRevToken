# LookRevToken

Source file [../../LookRevToken.sol](../../LookRevToken.sol)

First review commit [https://github.com/LookRevTeam/LookRevToken/blob/5761ecf12e965af0a5b21caee9964e36b9b10466/LookRevCrowdSaleToken.sol](https://github.com/LookRevTeam/LookRevToken/blob/5761ecf12e965af0a5b21caee9964e36b9b10466/LookRevCrowdSaleToken.sol).

Second review commit [https://github.com/LookRevTeam/LookRevToken/blob/2ce6918c3b06b088338428c5a6ad39a0971ffe58/LookRevCrowdSaleToken.sol](https://github.com/LookRevTeam/LookRevToken/blob/2ce6918c3b06b088338428c5a6ad39a0971ffe58/LookRevCrowdSaleToken.sol).

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

// BK NOTE - Would be safer to use the `acceptOwnership()` pattern
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

  function transferOwnership(address _newOwner) onlyOwner {
    if (_newOwner != address(0)) {
      newOwner = _newOwner;
    }
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
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
// BK ERROR - There are two errors in `transferFrom(...)`
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

    // BK Ok - There were two errors in the first version which has now been fixed
    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
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
        //         - `!((_value == 0) || (allowed[msg.sender][_spender] == 0))`
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
    address public wallet;

    // BK Ok
    mapping(address => bool) public kycRequired;

    // Start - Wednesday, August 16, 2017 10:00:00 AM GMT-07:00 DST
    // End - Saturday, September 16, 2017 10:00:00 AM GMT-07:00 DST
    // BK Ok - `new Date(1502902800 * 1000).toUTCString()` => "Wed, 16 Aug 2017 17:00:00 UTC"
    uint public constant START_DATE = 1502902800;
    // BK Ok - `new Date(1505581200 * 1000).toUTCString()` => "Sat, 16 Sep 2017 17:00:00 UTC"
    uint public constant END_DATE = 1505581200;

    // BK Ok
    uint public constant DECIMALSFACTOR = 10**uint(decimals);
    // BK Ok - 10,000,000
    uint public constant TOKENS_SOFT_CAP =   10000000 * DECIMALSFACTOR;
    // BK Ok - 2,000,000,000
    uint public constant TOKENS_HARD_CAP = 2000000000 * DECIMALSFACTOR;
    // BK Ok - 4,000,000,000
    uint public constant TOKENS_TOTAL =    4000000000 * DECIMALSFACTOR;

    // 1 KETHER = 2,400,000 tokens
    // 1 ETH = 2,400 tokens
    // Presale 20% discount 1 ETH = 3,000 tokens
    // Presale 10% discount 1 ETH = 2,667 tokens
    uint public tokensPerKEther = 3000000;
    // BK Ok
    uint public CONTRIBUTIONS_MIN = 0 ether;
    // BK Ok
    uint public CONTRIBUTIONS_MAX = 0 ether;
    uint public constant KYC_THRESHOLD = 10000 * DECIMALSFACTOR;

    // BK Ok - Constructor
    function LookRevToken(address _wallet, uint _initialSupply) {
      // BK Ok
      wallet = _wallet;
      // BK Ok
      owner = msg.sender;
      // BK Ok
      totalSupply = _initialSupply;
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
    // BK Ok - Owner can change the rate before the crowdsale starts
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
    function proxyPayment(address participant) payable {

        // BK Ok
        require(!finalised);

        // BK Ok
        require(now <= END_DATE);

        // BK Ok
        require(msg.value > CONTRIBUTIONS_MIN);
        // BK Ok - Could be `<=` instead of `<`
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

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
    function burnFrom(address _from, uint _amount) returns (bool success) {
        require(totalSupply >= _amount);

        if (balances[_from] >= _amount
            && allowed[_from][0x0] >= _amount
            && _amount > 0
            && balances[0x0] + _amount > balances[0x0]
        ) {
            balances[_from] = safeSub(balances[_from],_amount);
            balances[0x0] = safeAdd(balances[0x0],_amount);
            allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);
            totalSupply = safeSub(totalSupply,_amount);
            Transfer(_from, 0x0, _amount);
            return true;
        } else {
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