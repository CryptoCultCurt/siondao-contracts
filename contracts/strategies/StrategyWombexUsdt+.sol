// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Strategy.sol";
import "../connectors/Chainlink.sol";
import "../connectors/Wombex.sol";
import "../connectors/PancakeV2.sol";
import {IWombatRouter, WombatLibrary, IWombatAsset} from '../connectors/Wombat.sol';


contract StrategyWombexUsdtPlus is Strategy {

    // --- structs

    struct StrategyParams {
        address usdtPlus;
        address usdt;
        address usdc;
        address wom;
        address wmx;
        address lpUsdtPlus;
        address wmxLpUsdtPlus;
        address poolDepositor;
        address pool;
        address pancakeRouter;
        address wombatRouter;
        address oracleUsdt;
        string name;
    }

    // --- params

    IERC20 public usdt;
    IERC20 public usdc;
    IERC20 public usdtPlus;
    IERC20 public wom;
    IERC20 public wmx;

    IWombatAsset public lpUsdtPlus;
    IWombexBaseRewardPool public wmxLpUsdtPlus;
    IWombexPoolDepositor public poolDepositor;
    address public pool;

    IPancakeRouter02 public pancakeRouter;

    uint256 public lpUsdtDm;


    IWombatRouter public wombatRouter;

    IPriceFeed public oracleUsdt;

    uint256 public usdtDm;
    uint256 public usdtPlusDm;
    uint256 public lpUsdtPlusDm;
    string public name;



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
        usdt = IERC20(params.usdt);
        usdc = IERC20(params.usdc);
        usdtPlus = IERC20(params.usdtPlus);
        wom = IERC20(params.wom);
        wmx = IERC20(params.wmx);
 

        lpUsdtPlus = IWombatAsset(params.lpUsdtPlus);
        wmxLpUsdtPlus = IWombexBaseRewardPool(params.wmxLpUsdtPlus);
        poolDepositor = IWombexPoolDepositor(params.poolDepositor);
        pool = params.pool;

        pancakeRouter = IPancakeRouter02(params.pancakeRouter);
        wombatRouter = IWombatRouter(params.wombatRouter);

        oracleUsdt = IPriceFeed(params.oracleUsdt);


        usdtDm = 10 ** IERC20Metadata(params.usdtPlus).decimals();
        usdtPlusDm = 10 ** IERC20Metadata(params.usdt).decimals();
        lpUsdtPlusDm = 10 ** IERC20Metadata(params.lpUsdtPlus).decimals();
        name = string(params.name);

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdt), "Some token not compatible");

        // swap usdt to usdtPlus
       // (uint256 reserveUsdc, uint256 reserveBusd,) = pool.getReserves();
        uint256 usdtBalance = usdt.balanceOf(address(this));
        console.log('swapping %s from %s to %s',usdtBalance,address(usdt),address(usdtPlus));
        address[] memory tokens = new address[](3);
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        tokens[2] = address(usdtPlus);
        address[] memory pools = new address[](2);
        pools[0] = pool;
        pools[1] = 0x9498563e47D7CFdFa22B818bb8112781036c201C;
        uint256 usdtPlusBalanceOut = WombatLibrary.getMultiAmountOut(
            wombatRouter,
            tokens,
            pools,
            usdtBalance
        );
      
       console.log('**usdtPlus Balance out %s',usdtPlusBalanceOut);
       if (usdtPlusBalanceOut > 0) {
        console.log('wombat Router: %s transfer: %s',address(wombatRouter),usdtPlusBalanceOut);
            WombatLibrary.multiSwap(
                wombatRouter,
                tokens,
                pools,
                usdtBalance,
                OvnMath.subBasisPoints(_oracleUsdtToUsdtPlus(usdtBalance), swapSlippageBP),
                address(this)
            );
       }
        console.log('Swapped for USDT+');
        // get LP amount min;
        uint256 usdtPlusBalance = usdtPlus.balanceOf(address(this));
        console.log('USDTPlus: %s',usdtPlusBalance);
        (uint256 lpUsdtPlusAmount,) = poolDepositor.getDepositAmountOut(address(lpUsdtPlus), usdtPlusBalance);
        uint256 lpUsdtPlusAmountMin = OvnMath.subBasisPoints(lpUsdtPlusAmount, stakeSlippageBP);
        console.log('getting LP amount min: %s',lpUsdtPlusAmountMin);
        // deposit
        usdtPlus.approve(address(poolDepositor), usdtPlusBalance);
        console.log('depositing usdt+ to pool depositor %s %s %s',address(lpUsdtPlus),usdtPlusBalance,lpUsdtPlusAmountMin);
        poolDepositor.deposit(address(lpUsdtPlus), usdtPlusBalance, lpUsdtPlusAmountMin, true);
        console.log('staked and finished usdt+');
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdt), "Some token not compatible");

       // calculate swap _amount busd to usdc
        address[] memory tokens = new address[](3);
        tokens[0] = address(usdtPlus);
        tokens[1] = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5; // hay
        tokens[2] = address(usdt);
        address[] memory pools = new address[](2);
        pools[0] = 0x9498563e47D7CFdFa22B818bb8112781036c201C;
        pools[1] = 0xa61dccC6c6E34C8Fbf14527386cA35589e9b8C27;
        // uint256 usdtAmountForUsdtPlusAmount = WombatLibrary.getMultiAmountOut(
        //     wombatRouter,
        //     tokens,
        //     pools,
        //     _amount
        // );
        console.log('unstaking %s ',_amount);
        // get busdAmount for _amount in usdc
        uint256 usdtAmount = _amount;

        // get withdraw amount for 1 LP
        (uint256 usdtAmountOneAsset,) = poolDepositor.getWithdrawAmountOut(address(lpUsdtPlus), lpUsdtPlusDm);
        console.log('usdtAmountOneAsset %s',usdtAmountOneAsset);

        // get LP amount
        uint256 lpUsdtPlusAmount = OvnMath.addBasisPoints(usdtAmount, stakeSlippageBP) * lpUsdtPlusDm / usdtAmountOneAsset;
        console.log('lpUsdtPlusAmount %s',lpUsdtPlusAmount);
        // withdraw
        wmxLpUsdtPlus.approve(address(poolDepositor), lpUsdtPlusAmount);
        poolDepositor.withdraw(address(lpUsdtPlus), lpUsdtPlusAmount, usdtAmount, address(this));

      //  swap busd to usdt
        uint256 usdtPlusBalance = usdtPlus.balanceOf(address(this));
        console.log('swapping %s from %s to %s',usdtPlusBalance,address(usdtPlus),address(usdt));


        uint256 usdtBalanceOut = WombatLibrary.getMultiAmountOut(
            wombatRouter,
            tokens,
            pools,
            usdtPlusBalance
        );

        console.log('**usdt Balance out %s',usdtBalanceOut);
        
        if (usdtBalanceOut > 0) {
            console.log('wombat Router: %s transfer: %s',address(wombatRouter),usdtBalanceOut);
            WombatLibrary.multiSwap(
                wombatRouter,
                tokens,
                pools,
                usdtPlusBalance,
                OvnMath.subBasisPoints(_oracleUsdtToUsdtPlus(usdtPlusBalance), swapSlippageBP),
                address(this)
            );
        }

        return usdt.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

       require(_asset == address(usdt), "Some token not compatible");
        address[] memory tokens = new address[](3);
        tokens[0] = address(usdtPlus);
        tokens[1] = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5; // hay
        tokens[2] = address(usdt);
        address[] memory pools = new address[](2);
        pools[0] = 0x9498563e47D7CFdFa22B818bb8112781036c201C;
        pools[1] = 0xa61dccC6c6E34C8Fbf14527386cA35589e9b8C27;

        // get busd amount min
        uint256 lpUsdtPlusBalance = wmxLpUsdtPlus.balanceOf(address(this));
        if (lpUsdtPlusBalance == 0) {
            return usdtPlus.balanceOf(address(this));
        }
        (uint256 usdtPlusAmount,) = poolDepositor.getWithdrawAmountOut(address(lpUsdtPlus), lpUsdtPlusBalance);
        uint256 usdtPlusAmountMin = OvnMath.subBasisPoints(usdtPlusAmount, stakeSlippageBP);

        // withdraw
        wmxLpUsdtPlus.approve(address(poolDepositor), lpUsdtPlusBalance);
        poolDepositor.withdraw(address(lpUsdtPlus), lpUsdtPlusBalance, usdtPlusAmountMin, address(this));

        // swap busd to usdc
        uint256 usdtPlusBalance = usdtPlus.balanceOf(address(this));
        uint256 usdtBalanceOut = WombatLibrary.getMultiAmountOut(
            wombatRouter,
            tokens,
            pools,
            usdtPlusBalance
        );
       
        if (usdtBalanceOut > 0) {
            WombatLibrary.multiSwap(
                wombatRouter,
                tokens,
                pools,
                usdtPlusBalance,
                OvnMath.subBasisPoints(_oracleUsdtToUsdtPlus(usdtPlusBalance), swapSlippageBP),
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
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 usdtPlusBalance = usdtPlus.balanceOf(address(this));

        address[] memory tokens = new address[](3);
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        tokens[2] = address(usdtPlus);
        address[] memory pools = new address[](2);
        pools[0] = pool;
        pools[1] = 0x9498563e47D7CFdFa22B818bb8112781036c201C;

        uint256 lpUsdtPlusBalance = wmxLpUsdtPlus.balanceOf(address(this));
        if (lpUsdtPlusBalance > 0) {
            (uint256 usdtPlusAmount,) = poolDepositor.getWithdrawAmountOut(address(lpUsdtPlus), lpUsdtPlusBalance);
            usdtPlusBalance += usdtPlusAmount;
        }

        if (usdtPlusBalance > 0) {
            if (nav) {
                usdtBalance += _oracleUsdtPlusToUsdt(usdtPlusBalance);
            } else {
                usdtBalance += WombatLibrary.getMultiAmountOut(
                wombatRouter,
                tokens,
                pools,
                usdtPlusBalance
            );
                
            }
        }

        return usdtBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        uint256 lpUsdtPlusBalance = wmxLpUsdtPlus.balanceOf(address(this));
        if (lpUsdtPlusBalance > 0) {
            wmxLpUsdtPlus.getReward(address(this), false);
        }

        // sell rewards
        uint256 totalUsdt;
        uint256 totalUsdtPlus;

        uint256 womBalance = wom.balanceOf(address(this));
        if (womBalance > 0) {
            uint256 amountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(wom),
                address(usdt),
                womBalance
            );

            if (amountOut > 0) {
                totalUsdt += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wom),
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
                address(usdt),
                wmxBalance
            );

            if (amountOut > 0) {
                totalUsdt += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wmx),
                    address(usdt),
                    wmxBalance,
                    amountOut * 99 / 100,
                    address(this)
                );
            }
        }

        if (totalUsdt > 0) {
            usdt.transfer(_to, totalUsdt);
        }
        console.log('rewards claimed from Wombex: %s',totalUsdt);
        return totalUsdt;
    }

    function _oracleUsdtPlusToUsdt(uint256 usdtPlusAmount) internal view returns (uint256) {
        uint256 priceUsdtPlus = uint256(oracleUsdt.latestAnswer());
        uint256 priceUsdt = uint256(oracleUsdt.latestAnswer());
        return ChainlinkLibrary.convertTokenToToken(usdtPlusAmount, usdtPlusDm, usdtDm, priceUsdtPlus, priceUsdt);
    }

    function _oracleUsdtToUsdtPlus(uint256 usdtAmount) internal view returns (uint256) {
        uint256 priceUsdtPlus = uint256(oracleUsdt.latestAnswer());
        uint256 priceUsdt = uint256(oracleUsdt.latestAnswer());
        return ChainlinkLibrary.convertTokenToToken(usdtAmount, usdtDm, usdtPlusDm, priceUsdt, priceUsdtPlus);
    }

}