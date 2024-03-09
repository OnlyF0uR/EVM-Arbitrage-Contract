// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

contract Arbitrage is IFlashLoanRecipient, IUniswapV3SwapCallback  {
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
  
  ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  function swapV3(address _pool, address _in, int256 _amount, uint160 _sqrtPriceLimitX96) public {
    require(_amount != 0, "NA"); // Nought amount 
    require(IERC20(_in).balanceOf(address(this)) >= uint256(_amount), "NEF"); // Not enough funds


  }

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {}
}
