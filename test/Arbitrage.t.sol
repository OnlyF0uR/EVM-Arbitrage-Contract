// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

address constant WETH_MATIC_POOL = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

contract ArbitrageTest is Test {
    Arbitrage private arbit;

    function setUp() public {
      arbit = new Arbitrage(BALANCER_VAULT);

      deal({
        token: WETH,
        to: address(arbit),
        give: 100e18
      });

      console2.log("WETH balance", IERC20(WETH).balanceOf(address(arbit)));
    }

    function testV3Swap() public {
      arbit.swapV3(WETH_MATIC_POOL, WETH, 2e18, 0);
      assertGe(IERC20(WMATIC).balanceOf(address(this)), 0, "SF");
    }
}
