# LookRev Token Contract Audit

Status: Work in progress

First review commit [https://github.com/LookRevTeam/LookRevToken/blob/5761ecf12e965af0a5b21caee9964e36b9b10466/LookRevCrowdSaleToken.sol](https://github.com/LookRevTeam/LookRevToken/blob/5761ecf12e965af0a5b21caee9964e36b9b10466/LookRevCrowdSaleToken.sol).

Second review commit [https://github.com/LookRevTeam/LookRevToken/blob/2ce6918c3b06b088338428c5a6ad39a0971ffe58/LookRevCrowdSaleToken.sol](https://github.com/LookRevTeam/LookRevToken/blob/2ce6918c3b06b088338428c5a6ad39a0971ffe58/LookRevCrowdSaleToken.sol).

## Recommendation

### First Review

* **IMPORTANT** There is an error in the `transferFrom(...)` function. `&& allowed[_from][_to] >= _amount` should be
  `&& allowed[_from][msg.sender] >= _amount`. The `_from` account approves for `msg.sender` as the spender to spend an amount. The
  spender can send up to this amount to any other account, including itself.

  Also `allowed[_from][_to] = safeSub(allowed[_from][_to],_amount);` should be `allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);`.

  * [x] Fixed in second review

* **LOW IMPORTANCE** The event `TokensBought` should have the `newEtherBalance` parameter renamed to be `participantTokenBalance`.

  * [x] Fixed in second review

* **LOW IMPORTANCE** In `proxyPayment(...)` the comparison `if (msg.value > 10000 * DECIMALSFACTOR) {` should be set as a constant like 
  `uint public constant KYC_THRESHOLD = 10000 * DECIMALSFACTOR;` and the comparison changed to
  `if (msg.value > KYC_THRESHOLD) {`.

  * [x] Fixed in second review

* **LOW IMPORTANCE* Using the `acceptOwnership(...)` pattern for the *Ownable* contract provides a bit more safety if the contract owner needs to be updated. See [Owned.sol](https://github.com/openanx/OpenANXToken/blob/master/contracts/Owned.sol#L51-L55).

### Second Review

* **IMPORTANT** There is an error in the `burnFrom(...)` function. `&& allowed[_from][_from] >= _amount` should be `&& allowed[_from][0x0] >= _amount`
  and `allowed[_from][_from] = safeSub(allowed[_from][_from],_amount);` should be `allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);`.

<br />

<hr />

## Notes

<br />

<hr />

## Testing

<br />

<hr />
## Code Review

* [ ] [code-review/LookRevCrowdSaleToken.md](code-review/LookRevCrowdSaleToken.md).
  * [x] contract ERC20 
  * [x] contract SafeMath 
  * [x] contract Ownable 
  * [x] contract StandardToken is ERC20, Ownable, SafeMath 
  * [ ] contract LookRevToken is StandardToken
    * [ ] Check the burn function's use of the `allowed[...][...]` structure 

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for LookRev - July 24 2017. The MIT Licence.
