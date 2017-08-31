# LookRev Token Contract Audit

## Summary

Bok Consulting Pty Ltd was commissioned to perform an audit on the crowdsale and token Ethereum smart contract for
[LookRev](http://lookrev.com/)'s upcoming crowdsale.

This audit has been conducted on the LookRev's source code in commits
[5761ecf1](https://github.com/LookRevTeam/LookRevToken/tree/5761ecf12e965af0a5b21caee9964e36b9b10466) to
[98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165),
[e708b6c0](https://github.com/LookRevTeam/LookRevToken/tree/e708b6c01ad6514c7b212b91c39fa0f28b98b3bc) and
[c0e67cf1](https://github.com/LookRevTeam/LookRevToken/commit/c0e67cf1d9cb93b40d7aa930256723ab36a6598b).

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

### Crowdsale Mainnet Address

The following details will be updated with the latest contract details after deployment.

The *LookRevToken* crowdsale/token contract has been deployed to [0x21ae23b882a340a22282162086bc98d3e2b73018](https://etherscan.io/address/0x21ae23b882a340a22282162086bc98d3e2b73018#code) with the following parameters:

* START_DATE: 1504112400, or new Date(1504112400 * 1000).toUTCString() = **Wed, 30 Aug 2017 17:00:00 UTC**
* END_DATE: 1506790800, or new Date(1506790800 * 1000).toUTCString() = **Sat, 30 Sep 2017 17:00:00 UTC**
* initialSupply: new BigNumber("10000000000000000000000000").shift(-18) = **10,000,000**
* TOKENS_SOFT_CAP: new BigNumber("10000000000000000000000000").shift(-18) = **10,000,000**
* TOKENS_HARD_CAP: new BigNumber("2000000000000000000000000000").shift(-18) = **2,000,000,000**
* tokensPerKEther: **2,400,000** . The number of tokens per ether is 2,400

The crowdsale `wallet` has the address [0xaa33f0e76ae8ad78751f949df0f8ca0bf7a0e8f0](https://etherscan.io/address/0xaa33f0e76ae8ad78751f949df0f8ca0bf7a0e8f0).

<br />

### Crowdsale Statistics

`{TBA}`

<br />

### Crowdsale/Token Contract

Ethers contributed by participants to the crowdsale contract will result in LOK tokens being allocated to the participant's 
account in the token contract. The contributed ethers are sent immediately via the crowdsale/token contract to the crowdsale
wallet.

The LOK tokens are transferable once the crowdsale `finalise()` function is executed, and this can be done after the minimum
funding goal is reached, or after the end of the crowdsale.

There is a KYC (Know-Your-Client) threshold where participants contributing above this threshold will be required to be
KYC verified before being able to transfer their tokens.

The token contract is [ERC20](https://github.com/ethereum/eips/issues/20) compliant with the following features:

* `decimals` is correctly defined as `uint8` instead of `uint256`
* `transfer(...)` and `transferFrom(...)` will return false if there is an error instead of throwing an error.
* `transfer(...)` and `transferFrom(...)` have not been built with a check on the size of the data being passed
* `approve(...)` has a requirement that non-zero approval limits need to be set to 0 before a new non-zero limit can be set

There is a `burnFrom(...)` function that is used to burn tokens from accounts, but this requires the account to `approve(...)` the
number of tokens that can be burnt.

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
  * [Crowdsale Mainnet Address](#crowdsale-mainnet-address)
  * [Crowdsale Statistics](#crowdsale-statistics)
  * [Crowdsale/Token Contract](#crowdsaletoken-contract)
* [Table Of Contents](#table-of-contents)
* [Recommendations](#recommendations)
* [Notes](#notes)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Testing](#testing)
* [Code Review](#code-review)
* [References](#references)

<br />

<hr />

## Recommendations

* **HIGH IMPORTANCE** There is an error in the `transferFrom(...)` function. `&& allowed[_from][_to] >= _amount` should be
  `&& allowed[_from][msg.sender] >= _amount`. The `_from` account approves for `msg.sender` as the spender to spend an amount. The
  spender can send up to this amount to any other account, including itself.
  
  Also `allowed[_from][_to] = safeSub(allowed[_from][_to],_amount);` should be `allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);`.
  * [x] Fixed in [98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165)

* **LOW IMPORTANCE** The event `TokensBought` should have the `newEtherBalance` parameter renamed to be `participantTokenBalance`.
  * [x] Fixed in [98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165)

* **LOW IMPORTANCE** In `proxyPayment(...)` the comparison `if (msg.value > 10000 * DECIMALSFACTOR) {` should be set as a constant like 
  `uint public constant KYC_THRESHOLD = 10000 * DECIMALSFACTOR;` and the comparison changed to
  `if (msg.value > KYC_THRESHOLD) {`.
  * [x] Fixed in [98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165)

* **LOW IMPORTANCE** Using the `acceptOwnership(...)` pattern for the *Ownable* contract provides a bit more safety if the contract owner needs to be updated. See [Owned.sol](https://github.com/openanx/OpenANXToken/blob/master/contracts/Owned.sol#L51-L55).
  * [x] Fixed in [98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165)

* **MEDIUM IMPORTANCE** There is an error in the `burnFrom(...)` function. `&& allowed[_from][_from] >= _amount` should be `&& allowed[_from][0x0] >= _amount`
  and `allowed[_from][_from] = safeSub(allowed[_from][_from],_amount);` should be `allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);`.
  * [x] Fixed in [98e7e6a5](https://github.com/LookRevTeam/LookRevToken/tree/98e7e6a52a59d949e038968af34442e17ec24165)

* **LOW IMPORTANCE** `uint public initialSupply = 10000000 ...` should be `uint public constant INITIAL_SUPPLY = 10000000 ...`
  * [x] No further changes being made to the deployed contract, unless critical

* **MEDIUM IMPORTANCE** The KYC threshold from `uint public constant KYC_THRESHOLD = 1000000 * DECIMALSFACTOR;` is 1,000,000 ETH ~ 300,000,000 USD (@ 300 ETH/USD).
  * [x] KYC threshold set as expected

* **LOW IMPORTANCE** `owner = msg.sender;` in `function LookRevToken()` constructor is not necessary, as the owner variable is
  already set in the `function Ownable()` constructor
  * [x] No further changes being made to the deployed contract, unless critical

* **MEDIUM IMPORTANCE** There is no check that contributions cannot be made before `START_DATE`. Is this intended?
  * [x] No further changes being made to the deployed contract, unless critical

<br />

<hr />

## Notes

* There is a comment about discounts for presale participants. This will be handled manually by the LookRev who will register the tokens using the `addPrecommitment(...)` function.

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that funds contributed to
these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is that ensure the coded algorithms work
as expected. This audit does not guarantee that that the code is bugfree, but intends to highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the LookRev's business proposition, the individuals involved in
this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition before funding
any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on the
crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as duplicating
crowdsale websites. Potential participants should NOT just click on any links received through these messages. Scammers have also hacked
the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address matches the
audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Testing

* [x] Testing - script [test/01_test1.sh](test/01_test1.sh) with results [test/test1results.txt](test/test1results.txt):
* [x] Deploy crowdsale/token contract with initial supply
* [x] Add precommitments before crowdsale start
* [x] Wait for crowdsale start
* [x] Send contributions
* [x] Finalise the crowdsale
* [x] KYC accounts over the KYC threshold limit
* [x] `transfer(...)`, `approve(...)` and `transferFrom(...)` the tokens
  * [x] Accounts over the KYC threshold limit that are KYC verified can move tokens
  * [x] Accounts over the KYC threshold limit that have not been KYC verified cannot move tokens

See [test](test) for details on the testing.

<br />

<hr />

## Code Review

* [x] [code-review/LookRevCrowdSaleToken.md](code-review/LookRevCrowdSaleToken.md).
  * [x] contract ERC20 
  * [x] contract SafeMath 
  * [x] contract Ownable 
  * [x] contract StandardToken is ERC20, Ownable, SafeMath 
  * [x] contract LookRevToken is StandardToken

<br />

<hr />

## References

* [Ethereum Contract Security Techniques and Tips](https://github.com/ConsenSys/smart-contract-best-practices)

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for LookRev - Aug 10 2017. The MIT Licence.