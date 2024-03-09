// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Arbitrage is IFlashLoanRecipient  {
  IVault private immutable vault;
  address private immutable minter;

  struct Info {
    address tokenToBorrow;

    address poolOneRouter;
    address poolTwoRouter;

    address mediatorToken;
    uint24 poolOneFee;
    uint24 poolTwoFee;
    uint256 poolOneAmountOutMin;
    uint256 poolTwoAmountOutMin;
  }

  constructor(address _flashAddrProvider) {
    minter = msg.sender;
    vault = IVault(_flashAddrProvider);
  }

  modifier minterOnly {
    require(msg.sender == minter, "MO"); // Minter Only
    _;
  }

  function execute(Info memory _meta, uint256 _amount) external {
    IERC20[] memory tokens = new IERC20[](1);
    tokens[0] = IERC20(_meta.tokenToBorrow);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _amount;

    bytes memory userData = abi.encode(_meta);
    vault.flashLoan(this, tokens, amounts, userData);
  }

  function collect(address _token, address _receiver) external minterOnly {
    uint256 bal = IERC20(_token).balanceOf(address(this));
    require(bal > 0, "CO: NEF"); // Not enough funds

    IERC20(_token).transfer(_receiver, bal);
  }
  
  function performV3Swap(
    address _router,
    address tokenIn,
    address tokenOut,
    uint24 poolFee,
    uint256 amountIn
  ) public returns (uint256 amountOut) {
    ISwapRouter v3Router = ISwapRouter(_router);
    IERC20(tokenIn).approve(address(v3Router), amountIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fee: poolFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    amountOut = v3Router.exactInputSingle(params);
  }

  function performV2Swap(
    address _router,
    address tokenIn, 
    address tokenOut, 
    uint256 amountIn, 
    uint256 amountOutMin
  ) public returns (uint256 amountOut) {
    IUniswapV2Router02 v2Router = IUniswapV2Router02(_router);
    IERC20(tokenIn).approve(address(v2Router), amountIn);

    address[] memory path;
    path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    
    uint256[] memory amounts = v2Router.swapExactTokensForTokens(
      amountIn, amountOutMin, path, address(this), block.timestamp
    );

    return amounts[1];
  }

  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external override {
    require(msg.sender == address(vault), "MC");

    Info memory meta = abi.decode(userData, (Info));
    // Did we get the correct token?
    require(address(tokens[0]) == meta.tokenToBorrow, "TNE");

    uint256 midAmount;
    
    // Buy
    if (meta.poolOneAmountOutMin == 0) {
      midAmount = performV3Swap(meta.poolOneRouter, meta.tokenToBorrow, meta.mediatorToken, meta.poolOneFee, amounts[0]);
    } else {
      midAmount = performV2Swap(meta.poolOneRouter, meta.tokenToBorrow, meta.mediatorToken, amounts[0], meta.poolOneAmountOutMin);
    }

    // Sell
    if (meta.poolTwoAmountOutMin == 0) {
      performV3Swap(meta.poolTwoRouter, meta.mediatorToken, meta.tokenToBorrow, meta.poolTwoFee, midAmount);
    } else {
      performV2Swap(meta.poolTwoRouter, meta.mediatorToken, meta.tokenToBorrow, midAmount, meta.poolTwoAmountOutMin);
    }

    uint256 totalDebt = amounts[0] + feeAmounts[0];
    IERC20(meta.tokenToBorrow).transfer(address(vault), totalDebt);
  }
}
