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
    function tradeFeeBps() external view returns(unit feeBps);
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
Get all the support tokens list

```
function getListedTokens() external view returns (ERC20[] memory tokens)
```

**Parameters**

none

**Returns**

`tokens`  the supported tokes arraylist

---


## quote
Quote the destination token amount with the src token amount

```
function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`blockNumber` current blockNumber 

**Returns**

`destAmount`  Amount of Destination token  

---


## swapTokens
Execute a ERC20 token -> ERC20 token trade, on condition the caller must transfer amount of the src token to Settlement contract before call it, and require the balance difference value between after call and before call, please refer to sample for detail

```
function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`to` swap token to the Destination address

**Returns**

`destAmount`   Amount of actual destination tokens 

**Sample:**
```
function test_swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
    external returns (uint destAmount) {
        
    // quote the destAmont 
    uint quoteAmountOut = settlement.quote(srcToken,destToken,srcAmount,block.number);

    // require the quote destAmount is bigger than or equal to destAmountMin
    require(quoteAmountOut >= destAmountMin, "quote amount out is not enough");
    
    // record the destToken balance of of to address before swapTokens
    uint balanceBeforeSwap = srcToken.balanceOf(to);
    TransferHelper.safeTransferFrom(address(srcToken), msg.sender, address(settlement), srcAmount);
    
    uint swapAmountOut = settlement.swapTokens(srcToken,destToken,srcAmount,to);

    // query the destToken balance of to address and substract balance before swapTokens, 
    uint balanceAfterSwap = srcToken.balanceOf(to);
    uint actualAmountOut = balanceAfterSwap - balanceBeforeSwap;

    // require the balance difference value is bigger than or equal to destAmountMin.
    require(actualAmountOut >= destAmountMin, "actual amout out is not enough");
    
    return actualAmountOut;
}
```

---

## swapTokensWithTrust
Execute a ERC20 token -> ERC20 token trade, on condition the caller must approve Settlement

```
function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`  Amount of actual destination tokens 

**Sample:**
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


---

## getRateQtyStepFunction
Get feed rate steps

```
function getRateQtyStepFunction(ERC20 tradeToken, bool isBuy) external view returns (LibRates.StepFunction memory stepFunction)
```

**Parameters**

`tradeToken` Trade token 

`isBuy`  To buy the trade token or not 

`srcAmount` Amount of src token 

**Returns**

`stepFunction`  feed rate steps. one step is 1 / 10000 of the rate.  for detail please refer to the struct StepFunction in contract LibRates above


---

## getFeedRate
**To obtain the origin feed buy or sell rate of a token.**

```
function getFeedRate(ERC20 token, bool buy) external view returns (uint feedRate)
```

**Parameters**

`token`  token 

`isBuy`  buyFeedRate or not 

**Returns**

`feedRate` The origin feedRate


---

## getQuota

```
function getQuota(ERC20 tradeToken, bool isDestToken) external view returns (uint quota)
```

**Parameters**

`tradeToken`  Trade Token 

`isDestToken`  Whether tradeToken is the Destation token 

**Returns**

`quota` The quota that Settlement can trade 


---

## tradeFeeBps
Get the trade fee bps in Settlement contract,  1 is 1/10000 trade amount fee 

```
function tradeFeeBps() external view returns(unit feeBps)
```

**Parameters**

None

**Returns**

`feeBps` the trade fee bps, 1 bps => 1/10000


---


## How to aggregate settlement

1. Contact us to add your caller contract into whitelist of Settlement contract
2. Get all the support tokens by function **getListedTokens**
3. Quote destination token amount by function **quote**  
4. Trade:
    - swap tokens by function **swapTokens** if you do not trust the Settlement contract
    - swap tokens by function **swapTokensWithTrust** if you trust the Settlement contract


