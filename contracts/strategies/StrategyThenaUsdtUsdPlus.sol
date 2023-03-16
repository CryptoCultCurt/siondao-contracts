// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Strategy.sol";
import "../connectors/Chainlink.sol";
import "../connectors/Thena.sol";
import "../connectors/Wombat.sol";

import "hardhat/console.sol";

contract StrategyThenaUsdtUsdPlus is Strategy {
    // --- structs

    struct StrategyParams {
        address busdToken;
        address usdtToken;
        address usdPlus;
        address the;
        address pair;
        address router;
        address gauge;
        address wombatPool;
        address wombatRouter;
        address oracleBusd;
        address oracleUsdt;
    }

    // --- params

    IERC20 public busd;
    IERC20 public usdt;
    IERC20 public usdPlus;
    IERC20 public the;

    IPair public pair;
    IRouter public router;
    IGaugeV2 public gauge;
    IPool public wombatPool;

    IWombatRouter public wombatRouter;

    IPriceFeed public oracleBusd;
    IPriceFeed public oracleUsdt;

    uint256 public busdDm;
    uint256 public usdtDm;

    IERC20 public hay;
    uint256 public usdPlusDm;
    // --- events

    event StrategyUpdatedParams();

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Strategy_init();
    }

    // --- Setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        console.log("set params");
        busd = IERC20(params.busdToken);
        usdt = IERC20(params.usdtToken);
        usdPlus = IERC20(params.usdPlus);
        hay = IERC20(0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5);
        the = IERC20(params.the);
        pair = IPair(params.pair);
        router = IRouter(params.router);
        gauge = IGaugeV2(params.gauge);
        wombatPool = IPool(params.wombatPool);
        wombatRouter = IWombatRouter(params.wombatRouter);
        oracleBusd = IPriceFeed(params.oracleBusd);
        oracleUsdt = IPriceFeed(params.oracleUsdt);

        busdDm = 10 ** IERC20Metadata(params.busdToken).decimals();
        usdtDm = 10 ** IERC20Metadata(params.usdtToken).decimals();
        usdPlusDm = 10 ** IERC20Metadata(params.usdPlus).decimals();

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(address _asset, uint256 _amount) internal override {
        require(_asset == address(busd), "Non-compatible token");

        // get the reserves
        (uint256 reserveUsdt, uint256 reserveUsdPlus, ) = pair.getReserves();
        console.log("reserves");
        console.log(reserveUsdt);
        console.log(reserveUsdPlus);

        // the amount of busd to start
        uint256 busdBalance = busd.balanceOf(address(this));
        console.log("busd balance");
        console.log(busdBalance);

        // swap busd for usdt    //path/pool/amt/min/to/
        uint256 usdtBalanceOracle = ChainlinkLibrary.convertTokenToToken(
            busdBalance,
            busdDm,
            usdtDm,
            oracleBusd,
            oracleUsdt
        );

        WombatLibrary.swapExactTokensForTokens(
            wombatRouter,
            address(busd),
            address(usdt),
            address(wombatPool),
            busdBalance,
            OvnMath.subBasisPoints(usdtBalanceOracle, swapSlippageBP),
            address(this)
        );
        console.log("swapped for usdt");
        uint256 usdtQty = usdt.balanceOf(address(this));
        console.log(usdtQty);
        console.log(usdPlusDm);

        // get swap amounts for the pair
        uint256 usdPlusSwap = ThenaLibrary.getAmountToSwap(
            router,
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            usdtQty,
            reserveUsdt,
            reserveUsdPlus,
            usdtDm,
            usdPlusDm
        );
        console.log("amountUsdPlusToSwap");
        usdPlusSwap = usdPlusSwap/1000000000000;
        console.log(usdPlusSwap);
        
        // uint256  = busd.balanceOf(address(this));
        console.log("usdplus swap");
        console.log(address(usdt));
        console.log(address(usdPlus));
        console.log(usdPlusSwap);
        // USD+ IS ONLY SIX DECIMALS
        console.log('selling:');
        console.log(usdPlusSwap*1000000000000);
        console.log('for');
        console.log(OvnMath.subBasisPoints(usdPlusSwap, 40));

        uint256 swap = ThenaLibrary.swap(
            router,
            address(usdt),
            address(usdPlus),
            true,
            (usdPlusSwap*1000000000000),
            OvnMath.subBasisPoints((usdPlusSwap), 180),
            address(this)
        );
        console.log("swapped for usdplus");
        console.log(swap);

        // usdtQty will the amount returned from selling the busd

        uint256 usdPlusQty = usdPlus.balanceOf(address(this));
        usdtQty = usdt.balanceOf(address(this));
        console.log("amounts to deposit to LP");
        console.log(usdtQty);
        console.log(usdPlusQty);

        usdt.approve(address(router), usdtQty);
        usdPlus.approve(address(router), usdPlusQty);

        uint256 output = ThenaLibrary.getAmountOut(
            router,
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            usdtQty
        );

        console.log("amount out");
        console.log(output);
        if (output > usdPlusQty) {
            console.log("not enough usdPlus");
            output = ThenaLibrary.getAmountOut(
                router,
                address(usdPlus),
                address(usdt),
                pair.isStable(),
                usdPlusQty
            );

            router.addLiquidity(
                address(usdt),
                address(usdPlus),
                pair.isStable(),
                output,
                usdPlusQty,
                OvnMath.subBasisPoints(output, swapSlippageBP),
                OvnMath.subBasisPoints(usdPlusQty, swapSlippageBP),
                address(this),
                block.timestamp
            );
        } else {
            console.log("deposit lp");
            console.log(usdtQty);
            console.log(output);
            router.addLiquidity(
                address(usdt),
                address(usdPlus),
                pair.isStable(),
                usdtQty,
                usdPlusQty,
                0,
                0,
                address(this),
                block.timestamp
            );
        }

        // deposit to gauge
        uint256 lpBalance = pair.balanceOf(address(this));
        console.log("lpBalance");
        console.log(lpBalance);
        pair.approve(address(gauge), lpBalance);
        gauge.deposit(lpBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(busd), "Some token not compatible");

        // get amount LP tokens to unstake
        uint256 totalLpBalance = pair.totalSupply();
        (uint256 reserveUsdt, uint256 reserveBusd, ) = pair.getReserves();
        uint256 lpTokensToWithdraw = WombatLibrary.getAmountLpTokens(
            wombatRouter,
            address(busd),
            address(usdt),
            address(wombatPool),
            // add 1e13 to _amount for smooth withdraw
            _amount + 1e13,
            totalLpBalance,
            reserveBusd,
            reserveUsdt,
            busdDm,
            usdtDm
        );
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpTokensToWithdraw > lpBalance) {
            lpTokensToWithdraw = lpBalance;
        }

        // withdraw from gauge
        gauge.withdraw(lpTokensToWithdraw);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 busdLpBalance) = router
            .quoteRemoveLiquidity(
                address(usdt),
                address(busd),
                pair.isStable(),
                lpTokensToWithdraw
            );
        pair.approve(address(router), lpTokensToWithdraw);
        router.removeLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpTokensToWithdraw,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(busdLpBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        // swap usdt to busd
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 busdBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(usdt),
            address(busd),
            address(wombatPool),
            usdtBalance
        );
        if (busdBalanceOut > 0) {
            uint256 busdBalanceOracle = ChainlinkLibrary.convertTokenToToken(
                usdtBalance,
                usdtDm,
                busdDm,
                oracleUsdt,
                oracleBusd
            );
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(usdt),
                address(busd),
                address(wombatPool),
                usdtBalance,
                OvnMath.subBasisPoints(busdBalanceOracle, swapSlippageBP),
                address(this)
            );
        }

        return busd.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(busd), "Some token not compatible");

        uint256 lpBalance = gauge.balanceOf(address(this));

        // withdraw from gauge
        gauge.withdraw(lpBalance);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 busdLpBalance) = router
            .quoteRemoveLiquidity(
                address(usdt),
                address(busd),
                pair.isStable(),
                lpBalance
            );
        pair.approve(address(router), lpBalance);
        router.removeLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpBalance,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(busdLpBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        // swap usdt to busd
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 busdBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(usdt),
            address(busd),
            address(wombatPool),
            usdtBalance
        );
        if (busdBalanceOut > 0) {
            uint256 busdBalanceOracle = ChainlinkLibrary.convertTokenToToken(
                usdtBalance,
                usdtDm,
                busdDm,
                oracleUsdt,
                oracleBusd
            );
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(usdt),
                address(busd),
                address(wombatPool),
                usdtBalance,
                OvnMath.subBasisPoints(busdBalanceOracle, swapSlippageBP),
                address(this)
            );
        }

        return busd.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 busdBalance = busd.balanceOf(address(this));
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 usdPlusBalance = usdPlus.balanceOf(address(this));

        uint256 lpBalance = gauge.balanceOf(address(this));

        console.log('total value');
        console.log(busdBalance);
        console.log(usdtBalance);
        console.log(usdPlusBalance);
        console.log(lpBalance);

        if (lpBalance > 0) {
            (uint256 usdtLpBalance, uint256 usdPlusLpBalance) = router
                .quoteRemoveLiquidity(
                    address(usdt),
                    address(usdPlus),
                    pair.isStable(),
                    lpBalance
                );
            console.log('lp balance');
            console.log(usdtLpBalance);
            console.log(usdPlusLpBalance);

            usdtBalance += usdtLpBalance;
            usdPlusBalance += usdPlusLpBalance;
        }

        if (usdtBalance > 0) {
            console.log('get nav of usdtBalance');
            console.log('busd before');
            console.log(busdBalance);
            if (nav) {
                busdBalance += ChainlinkLibrary.convertTokenToToken(
                    usdtBalance,
                    usdtDm,
                    busdDm,
                    oracleUsdt,
                    oracleBusd
                );
            } else {
                busdBalance += WombatLibrary.getAmountOut(
                    wombatRouter,
                    address(usdt),
                    address(busd),
                    address(wombatPool),
                    usdtBalance
                );
            }

            console.log('busd after');
            console.log(busdBalance);
        }

        if (usdPlusBalance > 0) {
            console.log('get nav of usdPlusBalance');
            // if (nav) {
            //     busdBalance += ChainlinkLibrary.convertTokenToToken(
            //         usdPlusBalance,
            //         usdtDm,
            //         usdPlusDm,
            //         oracleUsdt,
            //         oracleBusd
            //     );
            // } else {
                console.log('busd before');
            console.log(busdBalance);
            console.log('converting usdPlus balance of');
            console.log(usdPlusBalance);

                    // convert to usdt in pool
                    uint256 usdtToConvert = ThenaLibrary.getAmountOut(
                    router,
                    address(usdPlus),
                    address(usdt),
                    pair.isStable(),
                    usdPlusBalance
                );

                console.log('usdPlus as USDT');
                console.log(usdtToConvert);
                // convert to busd
                busdBalance += WombatLibrary.getAmountOut(
                    wombatRouter,
                    address(usdt),
                    address(busd),
                    address(wombatPool),
                    usdtToConvert
                );

                console.log('busd after');
            console.log(busdBalance);
           //}
        }

        return busdBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {
        console.log("claimrewards");
        // claim rewards
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpBalance > 0) {
            gauge.getReward();
        }

        // sell rewards
        uint256 totalBusd;

        uint256 theBalance = the.balanceOf(address(this));
        if (theBalance > 0) {
            uint256 theAmountOut = ThenaLibrary.getAmountOut(
                router,
                address(the),
                address(busd),
                false,
                theBalance
            );
            if (theAmountOut > 0) {
                totalBusd += ThenaLibrary.swap(
                    router,
                    address(the),
                    address(busd),
                    false,
                    theBalance,
                    OvnMath.subBasisPoints(theAmountOut, 10),
                    address(this)
                );
            }
        }

        if (totalBusd > 0) {
            busd.transfer(_to, totalBusd);
        }

        return totalBusd;
    }
}
