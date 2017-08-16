#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENTEMPSOL=`grep ^TOKENTEMPSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

BLOCKSINDAY=10

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+75" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*3" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE            = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD        = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "TOKENSOL        = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENTEMPSOL    = '$TOKENTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS         = '$TOKENJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA  = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS       = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT     = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS    = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME     = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME       = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME         = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $TOKENSOL $TOKENTEMPSOL`

# --- Modify parameters ---
`perl -pi -e "s/START_DATE \= 1504112400;/START_DATE \= $STARTTIME; \/\/ $STARTTIME_S/" $TOKENTEMPSOL`
`perl -pi -e "s/END_DATE = 1506790800;/END_DATE \= $ENDTIME; \/\/ $ENDTIME_S/" $TOKENTEMPSOL`
`perl -pi -e "s/KYC_THRESHOLD \= 1000000/KYC_THRESHOLD \= 50000/" $TOKENTEMPSOL`

DIFFS1=`diff $TOKENSOL $TOKENTEMPSOL`
echo "--- Differences $TOKENSOL $TOKENTEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc --optimize --combined-json abi,bin,interface $TOKENTEMPSOL`;" > $TOKENJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TOKENJS");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENTEMPSOL:LookRevToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENTEMPSOL:LookRevToken"].bin;

// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Token Contract With 10,000,000 Initial Supply";
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var initialTotalSupply = "10000000000000000000000000";

var token = tokenContract.new(wallet, initialTotalSupply, {from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfGasEqualsGasUsed(tokenTx, tokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var preCommitMessage = "Add PreCommitments";
// -----------------------------------------------------------------------------
console.log("RESULT: " + preCommitMessage);
var preCommit1Tx = token.addPrecommitment(account3, "1000000000000000000000", {from: contractOwnerAccount, gas: 400000});
var preCommit2Tx = token.addPrecommitment(account4, "10000000000000000000000", {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("preCommit1Tx", preCommit1Tx);
printTxData("preCommit2Tx", preCommit2Tx);
printBalances();
failIfGasEqualsGasUsed(preCommit1Tx, preCommitMessage + " - ac3 1,000 LOK");
failIfGasEqualsGasUsed(preCommit2Tx, preCommitMessage + " - ac4 10,000 LOK");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale start
// -----------------------------------------------------------------------------
var startTime = token.START_DATE();
var startTimeDate = new Date(startTime * 1000);
console.log("RESULT: Waiting until startTime at " + startTime + " " + startTimeDate +
  " currentDate=" + new Date());
while ((new Date()).getTime() <= startTimeDate.getTime()) {
}
console.log("RESULT: Waited until startTime at " + startTime + " " + startTimeDate +
  " currentDate=" + new Date());
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution";
// -----------------------------------------------------------------------------
console.log("RESULT: " + validContribution1Message);
var sendValidContribution1Tx = eth.sendTransaction({from: account5, to: tokenAddress, gas: 400000, value: web3.toWei("11000", "ether")});
var sendValidContribution2Tx = eth.sendTransaction({from: account6, to: tokenAddress, gas: 400000, value: web3.toWei("100000", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendValidContribution1Tx", sendValidContribution1Tx);
printTxData("sendValidContribution2Tx", sendValidContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(sendValidContribution1Tx, validContribution1Message + " - ac5 11,000 ETH = 33,000,000 LOK");
failIfGasEqualsGasUsed(sendValidContribution2Tx, validContribution1Message + " - ac6 100,000 ETH = 300,000,000 LOK");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finaliseMessage = "Finalise Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finaliseMessage);
var finaliseTx = token.finalise({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("finaliseTx", finaliseTx);
printBalances();
failIfGasEqualsGasUsed(finaliseTx, finaliseMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var kycMessage = "KYC Account5";
// -----------------------------------------------------------------------------
console.log("RESULT: " + kycMessage);
var kycTx = token.kycVerify(account5, false, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("kycTx", kycTx);
printBalances();
failIfGasEqualsGasUsed(kycTx, kycMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move Tokens After Crowdsale Finalised";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account7, "1000000000000", {from: account3, gas: 100000});
var moveToken2Tx = token.approve(account8,  "30000000000000000", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account9, "30000000000000000", {from: account8, gas: 100000});
var moveToken4Tx = token.transfer(account8, "40000000000000000000", {from: account5, gas: 100000});
var moveToken5Tx = token.transfer(account9, "50000000000000000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printTxData("moveToken4Tx", moveToken4Tx);
printTxData("moveToken5Tx", moveToken5Tx);
printBalances();
failIfGasEqualsGasUsed(moveToken1Tx, moveTokenMessage + " - transfer 0.000001 LOK ac3 -> ac7. CHECK for movement");
failIfGasEqualsGasUsed(moveToken2Tx, moveTokenMessage + " - approve 0.03 LOK ac4 -> ac8");
failIfGasEqualsGasUsed(moveToken3Tx, moveTokenMessage + " - transferFrom 0.03 LOK ac4 -> ac9. CHECK for movement");
failIfGasEqualsGasUsed(moveToken4Tx, moveTokenMessage + " - transfer 40 LOK ac5 KYC-ed -> ac8. CHECK for movement");
passIfGasEqualsGasUsed(moveToken5Tx, moveTokenMessage + " - transfer 50 LOK ac6 Not KYC-ed -> ac9. CHECK for NO movement");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
