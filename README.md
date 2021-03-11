# Settlement
A open swap for aggregator

## Settlement interface function
```
interface ISettlement {
    function getListedTokens() external view returns (ERC20[] memory tokens);
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount); 
    function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount);
    function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
    function getRateQtyStepFunction(ERC20 tradeToken, bool isBuy) external view returns (LibRates.StepFunction memory stepFunction);
    function getFeedRate(ERC20 token, bool buy) external view returns (uint feedRate);
    function getQuota(ERC20 tradeToken, bool isDestToken) external view returns (uint quota);
}
```

```
contract LibRates {
        // bps - basic rate steps. one step is 1 / 10000 of the rate.
    struct StepFunction {
        int[] x; // quantity for each step. Quantity of each step includes previous steps.
        int[] y; // rate change per quantity step  in bps.
    }
}
```

---


## getListedTokens
**Get all the support tokens list** 

function getListedTokens() external view returns (ERC20[] memory tokens)

**Parameters**

none

**Returns**

`tokens`  the supported tokes arraylist

---


## quote
**Quote the amount **

function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount)

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`blockNumber` current blockNumber 

**Returns**

`destAmount`  Amount of Destination token  

---


## swapTokens
**Execute a ERC20 token -> ERC20 token trade.**

function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount)

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`to` swap token to the Destination address

**Returns**

`destAmount`   Amount of actual destination tokens 

---


## swapTokensWithTrust

function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount)

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`  Amount of actual destination tokens 


---

## getRateQtyStepFunction

function getRateQtyStepFunction(ERC20 tradeToken, bool isBuy) external view returns (LibRates.StepFunction memory stepFunction)

**Parameters**

`tradeToken` Trade token 

`isBuy`  To buy the trade token or not 

`srcAmount` Amount of src token 

**Returns**

`stepFunction` basic rate steps. one step is 1 / 10000 of the rate.  for detail please refer to the struct StepFunction in contract LibRates above


---

# getFeedRate

function getFeedRate(ERC20 token, bool buy) external view returns (uint feedRate)

**Parameters**

`token`  token 

`isBuy`  buyFeedRate or not 

**Returns**

`feedRate` The origin feedRate


---

# getQuota

function getQuota(ERC20 tradeToken, bool isDestToken) external view returns (uint quota)

**Parameters**

`tradeToken`  Trade Token 

`isDestToken`  Whether tradeToken is the Destation token 

**Returns**

`quota` The quota that Settlement can trade 


---


# How to aggregate settlement

## 1, contact us to add your caller contract into whitelist of Settlement contract

## 2, get all the support tokens by function getTokenList: 
    function getListedTokens() external view returns (ERC20[] memory tokens);

## 3, quote: quote destToken amount  
### param: blockNumber should be current blockNumber      
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external 


## 4, swapTokens: you have no need to approve settlement contract
function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount);

before swapTokens : 
quote the destAmont and require the quote destAmount is bigger than or equal to destAmountMin;
transfer the token into the settlement contract;
check the destToken balance of to address; 

execute swapTokens

after swapTokens: 
you should check the destToken balance of to address and substract balance before swapTokens, 
require the balance difference value is bigger than or equal to destAmountMin.

**sample:**
```
function test_swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
    external returns (uint destAmount) {
        
    uint quoteAmountOut = settlement.quote(srcToken,destToken,srcAmount,block.number);
    require(quoteAmountOut >= destAmountMin, "quote amount out is not enough");
    
    uint balanceBeforeSwap = srcToken.balanceOf(to);
    TransferHelper.safeTransferFrom(address(srcToken), msg.sender, address(settlement), srcAmount);
    
    uint swapAmountOut = settlement.swapTokens(srcToken,destToken,srcAmount,to);
    uint balanceAfterSwap = srcToken.balanceOf(to);
    uint actualAmountOut = balanceAfterSwap - balanceBeforeSwap;
    require(actualAmountOut >= destAmountMin, "actual amout out is not enough");
    
    return actualAmountOut;
}
```

## 5, swapTokensWithTrust: you must approve settlement contract
    function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount); 
    
    sample:
    ```
     function test_swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
        external returns (uint destAmount){

        if(srcToken.allowance(address(this), address(settlement)) < srcAmount) {
            TransferHelper.safeApprove(address(srcToken), address(settlement), MAX_UINT);
        } 
        uint swapAmountOut = settlement.swapTokensWithTrust(srcToken, destToken, srcAmount, destAmountMin, to);
        return swapAmountOut;
    }
    ```