//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../../interface/IUniversalLiquidator.sol";
import "../../../interface/IVault.sol";
import "../../../interface/ICaviarChef.sol";
import "../../../interface/IRewardForwarder.sol";
import "../../../interface/pearl/IRouter.sol";
import "../../../library/Stablemath.sol";

import "hardhat/console.sol";

contract CaviarVaultStrategyOLD is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
    //using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StableMath for uint256;

    address[] public rewardTokens;
    address public rewardPool;
    address public underlying;
    address public rewardToken;
    address public strategist; // gnosis safe multisig
    address public vault; // veSion vault
    address public universalLiquidator; // for selling tokens
    address public protocolFeeReceiver;
    address public profitSharingReceiver;
    address public targetToken;
    address public iFARM;
    uint256 public profitSharingNumerator;
    uint256 public platformFeeNumerator;
    uint256 public strategistFeeNumerator;
    uint256 public feeDenominator;
    address public governance;

    mapping(address => uint256) public userRewardPerTokenPaid;
    uint256 public rewardPerTokenStored;
    uint256 public constant DURATION = 7 days;

    // Timestamp for current period finish
    uint256 public periodFinish;
    // RewardRate for the rest of the PERIOD
    uint256 public rewardRate;
    uint256 public platformRewardRate;
    // Last time any user took action
    uint256 public lastUpdateTime;

    mapping(address => uint256) public rewards;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        profitSharingNumerator = 500;
        platformFeeNumerator = 300;
        strategistFeeNumerator = 100;
        feeDenominator = 10000;
        address usdr = address(0x40379a439D4F6795B6fc9aa5687dB461677A2dBa);
        rewardPool = 0x83C5022745B2511Bd199687a42D27BEFd025A9A9; //_rewardPool;
        underlying = 0x6AE96Cc93331c19148541D4D2f31363684917092; // _underlying;
        rewardToken = 0x40379a439D4F6795B6fc9aa5687dB461677A2dBa; // usdr;
        strategist = 0xECCb9B9C6fb7590a4d0588953B3170A1a84E3341; // gnosis safe multisig;
        vault = 0xda98485C7C2A279c6d5Df1177042c286C7dEf206; //_vault;
        universalLiquidator = 0x612cC8d1f3F4620CDC544ca60580110D81A4Ba87; //_universalLiquidator;
        protocolFeeReceiver = 0x832396CF98d035b3D82b25ceBDd1BD08a4Ddd1Fe; // 
        profitSharingReceiver = 0x832396CF98d035b3D82b25ceBDd1BD08a4Ddd1Fe; // 
        targetToken = 0x6AE96Cc93331c19148541D4D2f31363684917092; // caviar
        iFARM = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //usdc

        periodFinish=0;
        rewardRate=0;
        platformRewardRate=0;

        rewardTokens.push(usdr);
        rewardTokens.push(underlying);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ---  modifiers

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Restricted to vault");
        _;
    }

    /** @dev Updates the reward for a given address, before executing function */
    modifier updateReward(address _account) {
        // Setting of global vars
        (
            uint256 newRewardPerTokenStored
        ) = rewardPerToken();

        // If statement protects against loss in initialisation case
        if (newRewardPerTokenStored  > 0) {
            rewardPerTokenStored = newRewardPerTokenStored;
           // platformRewardPerTokenStored = newPlatformRewardPerTokenStored;

            lastUpdateTime = lastTimeRewardApplicable();

            // Setting of personal vars based on new globals
            if (_account != address(0)) {
                (rewards[_account]) = earned(_account);

                userRewardPerTokenPaid[_account] = newRewardPerTokenStored;
               // userPlatformRewardPerTokenPaid[_account] = newPlatformRewardPerTokenStored;
            }
        }
        _;
    }

    event ProfitsNotCollected(
        address indexed rewardToken,
        bool sell,
        bool floor
    );
    event ProfitLogInReward(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event ProfitAndBuybackLog(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event PlatformFeeLogInReward(
        address indexed treasury,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event StrategistFeeLogInReward(
        address indexed strategist,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );

    event RewardAdded(uint256 reward, uint256 platformReward);

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public onlyVault {
        console.log('withdraw all to vault called');
        address _underlying = underlying;
        uint256 balanceBefore = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        console.log('balance before', balanceBefore);
        _claimReward();
        console.log('claimed reward');
        uint256 balanceAfter = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        console.log('balance after', balanceAfter);
        uint256 claimedUnderlying = balanceAfter.sub(balanceBefore);
        console.log('claimed underlying', claimedUnderlying);
        _withdrawUnderlyingFromPool(_rewardPoolBalance());
        console.log('withdrew underlying from pool', _rewardPoolBalance());
        _liquidateReward(claimedUnderlying);
        console.log('liquidated reward ', claimedUnderlying);
        address underlying_ = underlying;
        console.log('transferring to vault', IERC20Upgradeable(underlying_).balanceOf(address(this)));
        IERC20Upgradeable(underlying_).safeTransfer(
            vault,
            IERC20Upgradeable(underlying_).balanceOf(address(this))
        );
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 _amount) onlyVault public {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        address underlying_ = underlying;
        uint256 entireBalance = IERC20Upgradeable(underlying_).balanceOf(
            address(this)
        );

        if (_amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = _amount.sub(entireBalance);
            uint256 toWithdraw = MathUpgradeable.min(
                _rewardPoolBalance(),
                needToWithdraw
            );
            _withdrawUnderlyingFromPool(toWithdraw);
        }
        console.log('transferring to vault called from withdrawToVault');
        IERC20Upgradeable(underlying_).safeTransfer(vault, _amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool == address(0)) {
            return IERC20Upgradeable(underlying).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return
            _rewardPoolBalance().add(
                IERC20Upgradeable(underlying).balanceOf(address(this))
            );
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyAdmin {
        // To make sure that governance cannot come in and take away the coins
        require(
            !unsalvagableTokens(token),
            "token is defined as not salvagable"
        );
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    function sweepToVault() external onlyVault {
        address _underlying = underlying;
        uint256 entireBalance = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        withdrawToVault(entireBalance);
    }
    // from mStable //////////////////////

    /**
     * @dev Calculates the amount of unclaimed rewards a user has earned
     * @param _account User address
     * @return Total reward amount earned
     */


   // **
   //  * @dev Calculates the amount of unclaimed rewards a user has earned
   //  * @return 'Reward' per staked token
   //  */


   /**
     * @dev Get the total amount of the staked token
     * @return uint256 total supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get the balance of a given account
     * @param _account User for which to retrieve balance
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

   /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() public view  returns (uint256) {
        return StableMath.min(block.timestamp, periodFinish);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards a user has earned
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) public view  returns (uint256) {
        // current rate per token - rate user previously received
        (uint256 currentRewardPerToken) = rewardPerToken();
        uint256 userRewardDelta = currentRewardPerToken - userRewardPerTokenPaid[_account];
        // uint256 userPlatformRewardDelta = currentPlatformRewardPerToken -
        //     userPlatformRewardPerTokenPaid[_account];
        // new reward = staked tokens * difference in rate
        uint256 stakeBalance = balanceOf(_account);
        uint256 userNewReward = stakeBalance.mulTruncate(userRewardDelta);
     //   uint256 userNewPlatformReward = stakeBalance.mulTruncate(userPlatformRewardDelta);
        // add to previous rewards
        return (rewards[_account] + userNewReward);
    }

    function rewardPerToken() public view  returns (uint256) {
        // If there is no StakingToken liquidity, avoid div(0)
        uint256 stakedTokens = totalSupply();
        if (stakedTokens == 0) {
            return (rewardPerTokenStored);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
       
        // return summed rate
        return (
            rewardPerTokenStored + unitsToDistributePerToken
        );
    }

    function _notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        require(_reward < 1e24, "Cannot notify with more than a million units");

        // uint256 newPlatformRewards = platformToken.balanceOf(address(this));
        // if (newPlatformRewards > 0) {
        //     platformToken.safeTransfer(address(platformTokenVendor), newPlatformRewards);
        // }

        uint256 currentTime = block.timestamp;
        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            rewardRate = _reward / DURATION;
          //  platformRewardRate = newPlatformRewards / DURATION;
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * rewardRate;
            rewardRate = (_reward + leftoverReward) / DURATION;

            //uint256 leftoverPlatformReward = remaining * platformRewardRate;
       //     platformRewardRate = (newPlatformRewards + leftoverPlatformReward) / DURATION;
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime + DURATION;

        emit RewardAdded(_reward,0);
    }


    function doHardWork() external onlyVault { // we don't want to call this directly as the vault must first transfer the funds to the strategy
        address _underlying = underlying;
        uint256 balanceBefore = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        _claimReward();
        uint256 balanceAfter = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
       // _investAllunderlying();
        console.log("invested");
        console.log("balance before", balanceBefore);
        console.log("balance after", balanceAfter);
        uint256 claimedUnderlying = balanceAfter.sub(balanceBefore);
        console.log("claimed rewards: %s CVR", claimedUnderlying);
        uint256 claimedUSDR = IERC20Upgradeable(iFARM).balanceOf(address(this));
        console.log("claimed rewards %s USDR", claimedUSDR);
       // _notifyRewardAmount(claimedUnderlying); // TODO: New stuff
        _liquidateReward(claimedUnderlying);
        _investAllunderlying();
        console.log("liquidated");

    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken || token == underlying);
    }

    /**
     * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    // function setSell(bool s) public  {
    //   _setSell(s);
    // }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    // function emergencyExit() public  {
    //   _emergencyExitRewardPool();
    //   _setPausedInvesting(true);
    // }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */
    // function continueInvesting() public  {
    //   _setPausedInvesting(false);
    // }

    function rewardPoolBalance() public view returns (uint256 balance) {
        (balance, ) = ICaviarChef(rewardPool).userInfo(address(this));
    }

    function pendingReward() public view returns (uint256) {
        return ICaviarChef(rewardPool).pendingReward(address(this));
    }

    function addRewardToken(address _token) public onlyAdmin {
        rewardTokens.push(_token);
    }

    function setVault(address _address) public onlyAdmin {
        vault = _address;
    }

    function setIFarm(address _address) public onlyAdmin {
        iFARM = _address;
    }

    function setRewardToken(address _address) public onlyAdmin {
        rewardToken = _address;
    }

    function setProfitSharingReceiver(address _address) public onlyAdmin {
        profitSharingReceiver = _address;
    }

    function setProtocolFeeReceiver(address _address) public onlyAdmin {
        protocolFeeReceiver = _address;
    }

    function setStrategist(address _address) public onlyAdmin {
        strategist = _address;
    }

    function setGovernance(address _address) public onlyAdmin {
        governance = _address;
    }

    function setUniversalLiquidator(address _address) public onlyAdmin {
        universalLiquidator = _address;
    }

    function setProfitSharingNumerator(uint256 _value) public onlyAdmin {
        profitSharingNumerator = _value;
    }

    function setPlatformFeeNumerator(uint256 _value) public onlyAdmin {
        platformFeeNumerator = _value;
    }

    function setStrategistFeeNumerator(uint256 _value) public onlyAdmin {
        strategistFeeNumerator = _value;
    }

    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    // ===== Internal Helper Functions =====

    function _notifyProfitInRewardToken(
        address _rewardToken,
        uint256 _rewardBalance
    ) internal {
        if (_rewardBalance > 100) {
            uint _feeDenominator = feeDenominator;
            uint256 strategistFee = _rewardBalance
                .mul(strategistFeeNumerator)
                .div(_feeDenominator);
            uint256 platformFee = _rewardBalance.mul(platformFeeNumerator).div(
                _feeDenominator
            );
            uint256 profitSharingFee = _rewardBalance
                .mul(profitSharingNumerator)
                .div(_feeDenominator);

            address strategyFeeRecipient = strategist;
        
            emit ProfitLogInReward(
                _rewardToken,
                _rewardBalance,
                profitSharingFee,
                block.timestamp
            );
            emit PlatformFeeLogInReward(
                protocolFeeReceiver,
                _rewardToken,
                _rewardBalance,
                platformFee,
                block.timestamp
            );
            emit StrategistFeeLogInReward(
                strategyFeeRecipient,
                _rewardToken,
                _rewardBalance,
                strategistFee,
                block.timestamp
            );

            console.log("distributing fees");
            // Distribute/send the fees
            _notifyFee(
                _rewardToken,
                profitSharingFee,
                strategistFee,
                platformFee
            );
        } else {
            emit ProfitLogInReward(_rewardToken, 0, 0, block.timestamp);
            emit PlatformFeeLogInReward(
                governance,
                _rewardToken,
                0,
                0,
                block.timestamp
            );
            emit StrategistFeeLogInReward(
                strategist,
                _rewardToken,
                0,
                0,
                block.timestamp
            );
        }
    }

    function _notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) internal {
        console.log("notifying fee");
        address liquidator = universalLiquidator;

        uint totalTransferAmount = _profitSharingFee.add(_strategistFee).add(
            _platformFee
        );
        require(totalTransferAmount > 0, "totalTransferAmount should not be 0");
        console.log("total transfer amount", totalTransferAmount);
        console.log("token", _token);
        uint256 balance = IERC20Upgradeable(_token).balanceOf(msg.sender);
        console.log("balance of msg.sender", balance);
        console.log("msg sender: ", msg.sender);
        console.log('called approvals for amount of %s', uint256(2**(256) - 1));
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), totalTransferAmount);
        console.log("transferred from msg.sender", msg.sender);
        address _targetToken = targetToken;

        if (_token != _targetToken) {
            console.log("not the target token, swapping");
            IERC20Upgradeable(_token).safeApprove(liquidator, 0);
            IERC20Upgradeable(_token).safeApprove(liquidator, _platformFee);

            uint amountOutMin = 1;

            if (_platformFee > 0) {
                console.log("swapping platform fee %s", _platformFee);
                console.log("target token %s", _targetToken);
                console.log("protocol fee receiver %s", protocolFeeReceiver);
                console.log("liquidator %s", liquidator);
                console.log("token %s", _token);
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    _targetToken,
                    _platformFee,
                    amountOutMin,
                    protocolFeeReceiver
                );
                console.log("swapped platform fee");
            }
        } else {
            console.log("sending protocol fee %s", _platformFee);
            console.log("protocol fee receiver %s", protocolFeeReceiver);
            console.log("target token %s", _targetToken);
            IERC20Upgradeable(_targetToken).safeTransfer(
                protocolFeeReceiver,
                _platformFee
            );
            console.log("sent protocol fee finished");
        }

        if (_token != iFARM) {
            console.log("swapping profitsharing fee %s", _profitSharingFee);
            console.log("and strategist fee %s", _strategistFee);
            console.log("liquidator %s", liquidator);
            console.log("token %s", _token);
            console.log("ifarm %s", iFARM);
            console.log("profit sharing receiver %s", profitSharingReceiver);
            console.log("strategist %s", strategist);

            IERC20Upgradeable(_token).safeApprove(liquidator, 0);
            IERC20Upgradeable(_token).safeApprove(
                liquidator,
                _profitSharingFee.add(_strategistFee)
            );
            console.log('approved liquidator');
     

            uint amountOutMin = 1;

            if (_profitSharingFee >= 1 ether) {
                console.log('converting profitShareReceiver fee of %s', _profitSharingFee);
                console.log('swap token %s to %s', _token, iFARM);
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    iFARM,
                    _profitSharingFee,
                    amountOutMin,
                    profitSharingReceiver
                );
                console.log('fee sent');
            }
            if (_strategistFee >= 1 ether) {
                console.log('converting strategist fee of %s', _strategistFee);
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    iFARM,
                    _strategistFee,
                    amountOutMin,
                    strategist
                );
                console.log('fee sent');
            }
        } else {
            console.log("iFARM stuff");
            if (_strategistFee >= 1 ether) {
                console.log('sending strategist fee of %s', _strategistFee);
                IERC20Upgradeable(iFARM).safeTransfer(
                    strategist,
                    _strategistFee
                );
                console.log('fee sent');
            }
            console.log('sending profit sharing fee of %s', _profitSharingFee);
            IERC20Upgradeable(iFARM).safeTransfer(
                profitSharingReceiver,
                _profitSharingFee
            );
        }
    }

    function _rewardPoolBalance() internal view returns (uint256 balance) {
        (balance, ) = ICaviarChef(rewardPool).userInfo(address(this));
    }

    function _emergencyExitRewardPool() internal {
        uint256 stakedBalance = _rewardPoolBalance();
        if (stakedBalance != 0) {
            _withdrawUnderlyingFromPool(stakedBalance);
        }
    }

    function _withdrawUnderlyingFromPool(uint256 amount) internal {
        address underlying_ = underlying;
        uint256 toWithdraw = MathUpgradeable.min(_rewardPoolBalance(), amount);
        if (toWithdraw > 0) {
            IERC20Upgradeable(underlying_).safeApprove(address(this), 0);
            IERC20Upgradeable(underlying_).safeApprove(address(this), toWithdraw);
            ICaviarChef(rewardPool).withdraw(toWithdraw, address(this));
        }
    }

    function _enterRewardPool() internal {
        console.log("entering reward pool");
        address underlying_ = underlying;
        address rewardPool_ = rewardPool;
        uint256 entireBalance = IERC20Upgradeable(underlying_).balanceOf(
            address(this)
        );

        IERC20Upgradeable(underlying_).safeApprove(rewardPool_, 0);
        IERC20Upgradeable(underlying_).safeApprove(rewardPool_, entireBalance);
        ICaviarChef(rewardPool_).deposit(entireBalance, address(this));
        console.log("deposited entire balance", entireBalance);
    }

    function _investAllunderlying() internal {
        console.log("investing all underlying");
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IERC20Upgradeable(underlying).balanceOf(address(this)) > 0) {
            console.log("entering reward pool");
            console.log(
                "amount: ",
                IERC20Upgradeable(underlying).balanceOf(address(this))
            );
            _enterRewardPool();
        } else {
            console.log("nothing to invest");
        }
    }

    function _claimReward() internal {
        ICaviarChef(rewardPool).harvest(address(this));
    }

    struct route {
        address tokenIn;
        address tokenOut;
        bool isStable;
    }

    function EstimateInUsd(uint256 _amount) external view  returns (uint256) {
            address pearlRouter = 0xcC25C0FD84737F44a7d38649b69491BBf0c7f083;
            IRouter.Route[] memory routes = new IRouter.Route[](3);
       
            routes[0].from = address(0x6AE96Cc93331c19148541D4D2f31363684917092); // caviar
            routes[0].to =  address(0x7238390d5f6F64e67c3211C343A410E2A3DEc142);  // pearl
            routes[0].stable = false;
 
            routes[1].from = address(0x7238390d5f6F64e67c3211C343A410E2A3DEc142); // pearl
            routes[1].to =  address(0x40379a439D4F6795B6fc9aa5687dB461677A2dBa);  // usdr
            routes[1].stable = false;

            routes[2].from = address(0x40379a439D4F6795B6fc9aa5687dB461677A2dBa); // usdr
            routes[2].to =  address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);  // usdc
            routes[2].stable = true;
        

        uint256[] memory returned = IRouter(pearlRouter)
            .getAmountsOut(
                _amount,
                routes
            );

        return returned[returned.length - 1];

        }


    function _liquidateReward(uint256 amountUnderlying) internal {
        // if (!sell()) {
        //   // Profits can be disabled for possible simplified and rapid exit
        //   emit ProfitsNotCollected(sell(), false);
        //   return;
        // }
        address _rewardToken = rewardToken;
        address _underlying = underlying;
        address _universalLiquidator = universalLiquidator;
        uint256 rewardsCollected = 0;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            console.log('liquidating REWARD token', token);
            uint256 lrewards;
            if (token == _underlying) {
                lrewards = amountUnderlying;
            } else {
                lrewards = IERC20Upgradeable(token).balanceOf(address(this));
                console.log('lrewards %s not underlying.', lrewards);
            }
            if (lrewards == 0) {
                console.log("no rewards for token", token);
                continue;
            }
            if (token != _rewardToken) {
                console.log("approving REWARD ", token, "for liquidation.  Not CVR so will be swapped.");
                console.log(
                    "swapping REWARD %s %s for %s",
                    lrewards,
                    token,
                    _rewardToken
                );
                console.log("universal liquidator", _universalLiquidator);
                IERC20Upgradeable(token).safeApprove(_universalLiquidator, 0);
                IERC20Upgradeable(token).safeApprove(
                    _universalLiquidator,
                    lrewards
                );
                rewardsCollected += IUniversalLiquidator(_universalLiquidator).swap(
                    token,
                    _rewardToken,
                    lrewards,
                    1,
                    address(this)
                );
                console.log('swapped reward token %s for %s (CVR)', token, _rewardToken);
                console.log('total rewards collected so far: %s', rewardsCollected);
            }
        }
        // THIS WOULD INCLUDE ANY CVR IN THE CONTRACT, NOT JUST WHAT WAS SWAPPED
        // uint256 rewardBalance = IERC20Upgradeable(_rewardToken).balanceOf(
        //     address(this)
        // );
        
        console.log("notifying profit", _rewardToken, rewardsCollected);
        _notifyProfitInRewardToken(_rewardToken, rewardsCollected);
        uint256 remainingRewardBalance = IERC20Upgradeable(_rewardToken)
            .balanceOf(address(this));
        console.log("remaining reward balance", remainingRewardBalance);

        if (remainingRewardBalance == 0) {
            return;
        }

        if (_underlying != _rewardToken) {
            IERC20Upgradeable(_rewardToken).safeApprove(
                _universalLiquidator,
                0
            );
            IERC20Upgradeable(_rewardToken).safeApprove(
                _universalLiquidator,
                remainingRewardBalance
            );
            IUniversalLiquidator(_universalLiquidator).swap(
                _rewardToken,
                _underlying,
                remainingRewardBalance,
                1,
                address(this)
            );
        }
    }

    function _isAddressInList(
        address _searchValue,
        address[] memory _list
    ) internal pure returns (bool) {
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _searchValue) {
                return true;
            }
        }
        return false;
    }
}
