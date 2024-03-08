// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";

contract Arbitrage is IFlashLoanRecipient  {
  IVault private constant vault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
  ) external {
    vault.flashLoan(this, tokens, amounts, userData);
  }

  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == vault);
    }
}
