// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Arbitrage is IFlashLoanRecipient  {
  IVault private immutable vault;
  address private immutable minter;

  struct SwapInfo {
    address poolAddress;
    address tokenIn;
    uint24 poolFee;
    bool isLegacy;
  }
  struct ArbitInfo {
    SwapInfo buy;
    SwapInfo sell;
  }

  constructor(address _flashAddrProvider) {
    minter = msg.sender;
    vault = IVault(_flashAddrProvider);
  }

  modifier minterOnly {
    require(msg.sender == minter, "MO"); // Minter Only
    _;
  }

  function execute(ArbitInfo memory _meta, uint256 _amount) external {
    // ...
  }

  function collect(address _token, address _receiver) external minterOnly {
    uint256 bal = IERC20(_token).balanceOf(address(this));
    require(bal > 0, "CO: NEF"); // Not enough funds

    IERC20(_token).transfer(_receiver, bal);
  }

  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external override {
    // ...
  }
  
  ISwapRouter constant v3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  
  function performV3Swap(
      address tokenIn,
      address tokenOut,
      uint24 poolFee,
      uint256 amountIn
  ) external returns (uint256 amountOut) {
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

  IUniswapV2Router private v2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  function performV2Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut) {
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
}
