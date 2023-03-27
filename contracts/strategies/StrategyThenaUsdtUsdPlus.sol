// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Strategy.sol";
import "../connectors/Chainlink.sol";
import "../connectors/Thena.sol";
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
    address public wombatPool;

    address public wombatRouter;

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
        wombatPool = address(params.wombatPool);
        wombatRouter = address(params.wombatRouter);
        oracleBusd = IPriceFeed(params.oracleBusd);
        oracleUsdt = IPriceFeed(params.oracleUsdt);

        busdDm = 10 ** IERC20Metadata(params.busdToken).decimals();
        usdtDm = 10 ** IERC20Metadata(params.usdtToken).decimals();
        usdPlusDm = 10 ** IERC20Metadata(params.usdPlus).decimals();

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(address _asset, uint256 _amount) internal override {
        require(_asset == address(usdt), "Non-compatible token");

        // get the reserves
        (uint256 reserveUsdt, uint256 reserveUsdPlus, ) = pair.getReserves();
        // console.log("reserves");
        // console.log(reserveUsdt);
        // console.log(reserveUsdPlus);

        // the amount of busd to start

       
        //console.log("swapped for usdt");
        uint256 usdtQty = usdt.balanceOf(address(this));
       // console.log(usdtQty);
        //console.log(usdPlusDm);

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

           usdPlusSwap = usdPlusSwap / 1000000000000;
          console.log('usdtQty: %s usdPlusSwap: %s',usdtQty,usdPlusSwap);

        ThenaLibrary.swap(
            router,
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            (usdPlusSwap * 1000000000000),
            0,
            //OvnMath.subBasisPoints((usdPlusSwap), 180),
            address(this)
        );
       
        // usdtQty will the amount returned from selling the busd

        uint256 usdPlusQty = usdPlus.balanceOf(address(this));
        usdtQty = usdt.balanceOf(address(this));

        usdt.approve(address(router), usdtQty);
        usdPlus.approve(address(router), usdPlusQty);

        uint256 output = ThenaLibrary.getAmountOut(
            router,
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            usdtQty
        );

        if (output > usdPlusQty) {
            //   console.log("not enough usdPlus");
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
            // console.log("deposit lp");
            // console.log(usdtQty);
            // console.log(output);
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
        // console.log("lpBalance");
        // console.log(lpBalance);
        pair.approve(address(gauge), lpBalance);
        gauge.deposit(lpBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {
       // require(_asset == address(usdt), "Some token not compatible");

        // get amount LP tokens to unstake
        uint256 totalLpBalance = pair.totalSupply();
        (uint256 reserveUsdt, uint256 reserveUsdPlus, ) = pair.getReserves();

        uint256 lpTokensToWithdraw = ThenaLibrary.getAmountLpTokens(
            router,
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            // add 1e13 to _amount for smooth withdraw
            _amount + 1e13,
            totalLpBalance,
            reserveUsdt,
            reserveUsdPlus,
            usdtDm,
            usdPlusDm
        );
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpTokensToWithdraw > lpBalance) {
            lpTokensToWithdraw = lpBalance;
        }

        // withdraw from gauge
        gauge.withdraw(lpTokensToWithdraw);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 usdPlusLPBalance) = router
            .quoteRemoveLiquidity(
                address(usdt),
                address(usdPlus),
                pair.isStable(),
                lpTokensToWithdraw
            );
        pair.approve(address(router), lpTokensToWithdraw);
        router.removeLiquidity(
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            lpTokensToWithdraw,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(usdPlusLPBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        

        // swap usdPlus to usdt 
        uint256 usdPlusBalance = usdPlus.balanceOf(address(this));
        uint256 usdtBalanceOut = ThenaLibrary.getAmountOut(
            router,
            address(usdPlus),
            address(usdt),
            pair.isStable(),
            usdPlusBalance
        );
        if (usdtBalanceOut > 0) {
        //    console.log('usd+: %s busd: %s',usdPlusBalance,busdBalanceOut);
         //   console.log('router: %s',address(router));

            ThenaLibrary.swap(
                router,
                address(usdPlus),
                address(usdt),
                pair.isStable(),
                usdPlusBalance,
                OvnMath.subBasisPoints((usdtBalanceOut), 180),
                address(this)
            );
        }

        return usdt.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {
      //  require(_asset == address(usdt), "Some token not compatible");

        console.log('inital balances: %s usdt: %s', usdPlus.balanceOf(address(this)), usdt.balanceOf(address(this)));
        uint256 lpBalance = gauge.balanceOf(address(this));

        // withdraw from gauge
        gauge.withdraw(lpBalance);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 usdPlusLpBalance) = router
            .quoteRemoveLiquidity(
                address(usdt),
                address(usdPlus),
                pair.isStable(),
                lpBalance
            );
        console.log('LPQUOTE: usdt: %s usdPlus: %s',usdtLpBalance,usdPlusLpBalance);
        pair.approve(address(router), lpBalance);
        router.removeLiquidity(
            address(usdt),
            address(usdPlus),
            pair.isStable(),
            lpBalance,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(usdPlusLpBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );
        console.log('tokens removed usdplus: %s usdt: %s', usdPlus.balanceOf(address(this)), usdt.balanceOf(address(this)));
        // swap usdPlus to usdt
        uint256 usdPlusBalance = usdPlus.balanceOf(address(this));
        uint256 usdtBalanceOut = ThenaLibrary.getAmountOut(
            router,
            address(usdPlus),
            address(usdt),
            pair.isStable(),
            usdPlusBalance
        );
        console.log('swapping usdPlus %s for %s',usdPlusBalance,usdtBalanceOut);
        if (usdtBalanceOut > 0) {
            ThenaLibrary.swap(
                router,
                address(usdPlus),
                address(usdt),
                pair.isStable(),
                usdPlusBalance,
                OvnMath.subBasisPoints((usdPlusBalance), 180),
                address(this)
            );
        }

        return usdt.balanceOf(address(this));
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
      console.log('TV usdt: %s usdPlus: %s',usdtBalance,usdPlusBalance);
        console.log('lp: %s busd: %s',lpBalance,busdBalance);
        if (lpBalance > 0) {
            (uint256 usdtLpBalance, uint256 usdPlusLpBalance) = router
                .quoteRemoveLiquidity(
                    address(usdt),
                    address(usdPlus),
                    pair.isStable(),
                    lpBalance
                );

            usdtBalance += usdtLpBalance;
            usdPlusBalance += usdPlusLpBalance;
        }

        if (usdPlusBalance > 0) {
            // convert to usdt in pool
        usdtBalance += ThenaLibrary.getAmountOut(
                router,
                address(usdPlus),
                address(usdt),
                pair.isStable(),
                usdPlusBalance
            );
        }

        return usdtBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {
        //("claimrewards");
        // claim rewards
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpBalance > 0) {
            gauge.getReward();
        }

        // sell rewards
        uint256 totalUsdt;

        uint256 theBalance = the.balanceOf(address(this));
        if (theBalance > 0) {
            uint256 theAmountOut = ThenaLibrary.getAmountOut(
                router,
                address(the),
                address(usdt),
                false,
                theBalance
            );
            if (theAmountOut > 0) {
                totalUsdt += ThenaLibrary.swap(
                    router,
                    address(the),
                    address(usdt),
                    false,
                    theBalance,
                    OvnMath.subBasisPoints(theAmountOut, 10),
                    address(this)
                );
            }
        }
       
       

        if (totalUsdt > 0) {
            usdt.transfer(_to, totalUsdt);
        }

        console.log('rewards claimed from USD+: %s',totalUsdt);

        return totalUsdt;
    }
}
