// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Strategy.sol";
import "../connectors/Chainlink.sol";
import "../connectors/Wombex.sol";
import "../connectors/PancakeV2.sol";
import {IWombatRouter, WombatLibrary,IWombatAsset} from '../connectors/Wombat.sol';


contract StrategyWombexBusd is Strategy {

    // --- structs

    struct StrategyParams {
        address busd;
        address usdc;
        address wom;
        address wmx;
        address lpBusd;
        address wmxLpBusd;
        address poolDepositor;
        address pool;
        address pancakeRouter;
        address wombatRouter;
        address oracleBusd;
        address oracleUsdc;
        address usdt;
    }

    // --- params

    IERC20 public busd;
    IERC20 public wom;
    IERC20 public wmx;

    IWombatAsset public lpBusd;
    IWombexBaseRewardPool public wmxLpBusd;
    IWombexPoolDepositor public poolDepositor;
    address public pool;

    IPancakeRouter02 public pancakeRouter;

    uint256 public lpBusdDm;

    IERC20 public usdc;

    IWombatRouter public wombatRouter;

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleBusd;

    uint256 public usdcDm;
    uint256 public busdDm;
    uint256 public usdtDm;

    IERC20  public usdt;

    // --- events

    event StrategyUpdatedParams();

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }

    // --- Setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        busd = IERC20(params.busd);
        usdc = IERC20(params.usdc);
        wom = IERC20(params.wom);
        wmx = IERC20(params.wmx);
        usdt = IERC20(params.usdt);

        lpBusd = IWombatAsset(params.lpBusd);
        wmxLpBusd = IWombexBaseRewardPool(params.wmxLpBusd);
        poolDepositor = IWombexPoolDepositor(params.poolDepositor);
        pool = params.pool;

        pancakeRouter = IPancakeRouter02(params.pancakeRouter);
        wombatRouter = IWombatRouter(params.wombatRouter);

        oracleBusd = IPriceFeed(params.oracleBusd);
        oracleUsdc = IPriceFeed(params.oracleUsdc);

        busdDm = 10 ** IERC20Metadata(params.busd).decimals();
        usdcDm = 10 ** IERC20Metadata(params.usdc).decimals();
        usdtDm = 10 ** IERC20Metadata(params.usdt).decimals();
        lpBusdDm = 10 ** IERC20Metadata(params.lpBusd).decimals();

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(busd), "Some token not compatible");

        // swap usdc to busd
        // uint256 usdcBalance = usdc.balanceOf(address(this));
        // uint256 busdBalanceOut = WombatLibrary.getAmountOut(
        //     wombatRouter,
        //     address(usdc),
        //     address(busd),
        //     pool,
        //     usdcBalance
        // );
        // if (busdBalanceOut > 0) {
        //     WombatLibrary.swapExactTokensForTokens(
        //         wombatRouter,
        //         address(usdc),
        //         address(busd),
        //         pool,
        //         usdcBalance,
        //         OvnMath.subBasisPoints(_oracleUsdcToBusd(usdcBalance), swapSlippageBP),
        //         address(this)
        //     );
        // }

        // get LP amount min
        uint256 busdBalance = busd.balanceOf(address(this));
        (uint256 lpBusdAmount,) = poolDepositor.getDepositAmountOut(address(lpBusd), busdBalance);
        uint256 lpBusdAmountMin = OvnMath.subBasisPoints(lpBusdAmount, stakeSlippageBP);

        // deposit
        busd.approve(address(poolDepositor), busdBalance);
        poolDepositor.deposit(address(lpBusd), busdBalance, lpBusdAmountMin, true);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdt), "Some token not compatible");

       // calculate swap _amount busd to usdc
        uint256 usdcAmountForBusdAmount = WombatLibrary.getAmountOut(
            wombatRouter,
            address(busd),
            address(usdt),
            pool,
            _amount
        );

        // get busdAmount for _amount in usdc
        uint256 busdAmount = _amount;

        // get withdraw amount for 1 LP
        (uint256 busdAmountOneAsset,) = poolDepositor.getWithdrawAmountOut(address(lpBusd), lpBusdDm);

        // get LP amount
        uint256 lpBusdAmount = OvnMath.addBasisPoints(busdAmount, stakeSlippageBP) * lpBusdDm / busdAmountOneAsset;

        // withdraw
        wmxLpBusd.approve(address(poolDepositor), lpBusdAmount);
        poolDepositor.withdraw(address(lpBusd), lpBusdAmount, busdAmount, address(this));

      //  swap busd to usdt
        uint256 busdBalance = busd.balanceOf(address(this));
        uint256 usdtBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(busd),
            address(usdt),
            pool,
            busdBalance
        );
        if (usdtBalanceOut > 0) {
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(busd),
                address(usdt),
                pool,
                busdBalance,
                OvnMath.subBasisPoints(_oracleBusdToUsdc(busdBalance), swapSlippageBP),
                address(this)
            );
        }

        return usdt.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

       // require(_asset == address(usdt), "Some token not compatible");

        // get busd amount min
        uint256 lpBusdBalance = wmxLpBusd.balanceOf(address(this));
        if (lpBusdBalance == 0) {
            return busd.balanceOf(address(this));
        }
        (uint256 busdAmount,) = poolDepositor.getWithdrawAmountOut(address(lpBusd), lpBusdBalance);
        uint256 busdAmountMin = OvnMath.subBasisPoints(busdAmount, stakeSlippageBP);

        // withdraw
        wmxLpBusd.approve(address(poolDepositor), lpBusdBalance);
        poolDepositor.withdraw(address(lpBusd), lpBusdBalance, busdAmountMin, address(this));

        // swap busd to usdc
        uint256 busdBalance = busd.balanceOf(address(this));
        uint256 usdtBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(busd),
            address(usdt),
            pool,
            busdBalance
        );
        if (usdtBalanceOut > 0) {
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(busd),
                address(usdt),
                pool,
                busdBalance,
                OvnMath.subBasisPoints(_oracleBusdToUsdc(busdBalance), swapSlippageBP),
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
        uint256 usdtBalance = usdc.balanceOf(address(this));
        uint256 busdBalance = busd.balanceOf(address(this));

        uint256 lpBusdBalance = wmxLpBusd.balanceOf(address(this));
        if (lpBusdBalance > 0) {
            (uint256 busdAmount,) = poolDepositor.getWithdrawAmountOut(address(lpBusd), lpBusdBalance);
            busdBalance += busdAmount;
        }

        if (busdBalance > 0) {
            if (nav) {
                usdtBalance += _oracleBusdToUsdc(busdBalance);
            } else {
                usdtBalance += WombatLibrary.getAmountOut(
                    wombatRouter,
                    address(busd),
                    address(usdt),
                    pool,
                    busdBalance
                );
            }
        }

        return usdtBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        uint256 lpBusdBalance = wmxLpBusd.balanceOf(address(this));
        if (lpBusdBalance > 0) {
            wmxLpBusd.getReward(address(this), false);
        }

        // sell rewards
        uint256 totalUsdt;
        uint256 totalBusd;

        uint256 womBalance = wom.balanceOf(address(this));
        if (womBalance > 0) {
            uint256 amountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(wom),
                address(busd),
                address(usdt),
                womBalance
            );

            if (amountOut > 0) {
                totalBusd += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wom),
                    address(busd),
                    address(usdt),
                    womBalance,
                    amountOut * 99 / 100,
                    address(this)
                );
            }
        }

        uint256 wmxBalance = wmx.balanceOf(address(this));
        if (wmxBalance > 0) {
            uint256 amountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(wmx),
                address(busd),
                address(usdt),
                wmxBalance
            );

            if (amountOut > 0) {
                totalBusd += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wmx),
                    address(busd),
                    address(usdt),
                    wmxBalance,
                    amountOut * 99 / 100,
                    address(this)
                );
            }
        }

        if (totalBusd > 0) {
            usdt.transfer(_to, totalBusd);
        }
        console.log('rewards claimed from Wombex: %s',totalBusd);
        return totalBusd;
    }

    function _oracleBusdToUsdc(uint256 busdAmount) internal view returns (uint256) {
        uint256 priceBusd = uint256(oracleBusd.latestAnswer());
        uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
        return ChainlinkLibrary.convertTokenToToken(busdAmount, busdDm, usdcDm, priceBusd, priceUsdc);
    }

    function _oracleUsdcToBusd(uint256 usdcAmount) internal view returns (uint256) {
        uint256 priceBusd = uint256(oracleBusd.latestAnswer());
        uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
        return ChainlinkLibrary.convertTokenToToken(usdcAmount, usdcDm, busdDm, priceUsdc, priceBusd);
    }

}