// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./interface/IControllerV2.sol";
import "hardhat/console.sol";
import "./library/Stablemath.sol";
import "./StakingTokenWrapper.sol";

import { AbstractVault, IERC20 } from "../mStable/vault/AbstractVault.sol";

contract RewardsVault is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ERC4626Upgradeable
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using StableMath for uint256;

    uint256 private _underlyingUnit;
    address private _underlying;
    uint256 private _vaultFractionToInvestNumerator;
    uint256 private _vaultFractionToInvestDenominator;
    IStrategy public strategy;
    uint256 public constant TEN = 10; // This implicitly converts it to `uint256` from uint8

    event Invest(uint256 amount);
    event StrategyAnnounced(address newStrategy, uint256 time);
    event StrategyChanged(address newStrategy, address oldStrategy);

    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 platformReward);

    /// REWARDS
    mapping(address => uint256) public userRewardPerTokenPaid;
    uint256 public rewardPerTokenStored;
    uint256 public constant DURATION = 86400;

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

    IVault public vault;

    /** @dev Updates the reward for a given address, before executing function */
    modifier updateReward(address _account) {
        // Setting of global vars
        console.log('update reward for ', _account);
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



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __ERC20_init("veTest", "veTest");
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


    // modifier streamRewards() {
    //     _streamRewards();
    //     _;
    // }


    // ======================= VIEWS =======================

    function decimals() public  pure override returns (uint8) {
        return 18;
    }

    function asset() public view override returns (address) {
        return _underlying;
    }

    function totalAssets() public view override returns (uint256) {
        return underlyingBalanceWithInvestment();
    }

    function assetsPerShare() public view returns (uint256) {
        return convertToAssets(TEN ** decimals());
    }

    function assetsOf(address _depositor) public view returns (uint256) {
        return (totalAssets() * balanceOf(_depositor)) / totalSupply();
    }

    function maxWithdraw(
        address _caller
    ) public view override returns (uint256) {
        return assetsOf(_caller);
    }

    // function previewWithdraw(
    //     uint256 _assets
    // ) public view override returns (uint256) {
    //     return convertToShares(_assets);
    // }

    function maxRedeem(address _caller) public view override returns (uint256) {
        return balanceOf(_caller);
    }

    function previewRedeem(
        uint256 _shares
    ) public view override returns (uint256) {
        return convertToAssets(_shares);
    }

    function getStrategy() public view returns (address) {
        return address(strategy);
    }

    function underlying() public view returns (address) {
        return _underlying;
    }

    function underlyingUnit() public view returns (uint256) {
        return _underlyingUnit;
    }

    function vaultFractionToInvestNumerator() public view returns (uint256) {
        return _vaultFractionToInvestNumerator;
    }

    function vaultFractionToInvestDenominator() public view returns (uint256) {
        return _vaultFractionToInvestDenominator;
    }

    /*
     * Returns the cash balance across all users in this contract.
     */
    function underlyingBalanceInVault() public view returns (uint256) {
        return IERC20Upgradeable(underlying()).balanceOf(address(this));
    }

    /* Returns the current underlying (e.g., DAI's) balance together with
     * the invested amount (if DAI is invested elsewhere by the strategy).
     */
    function underlyingBalanceWithInvestment() public view returns (uint256) {
        if (address(strategy) == address(0)) {
            // initial state, when not set
            return underlyingBalanceInVault();
        }
        return
            underlyingBalanceInVault().add(
                IStrategy(strategy).investedUnderlyingBalance()
            );
    }

    function getPricePerFullShare() public view returns (uint256) {
        return
            totalSupply() == 0
                ? underlyingUnit()
                : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(
                    totalSupply()
                );
    }

    /* get the user's share (in underlying)
     */
    function underlyingBalanceWithInvestmentForHolder(
        address holder
    ) external view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return
            underlyingBalanceWithInvestment().mul(balanceOf(holder)).div(
                totalSupply()
            );
    }

    function availableToInvestOut() public view returns (uint256) {
        uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
            .mul(vaultFractionToInvestNumerator())
            .div(vaultFractionToInvestDenominator());
        uint256 alreadyInvested = IStrategy(strategy)
            .investedUnderlyingBalance();
        if (alreadyInvested >= wantInvestInTotal) {
            return 0;
        } else {
            uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
            return
                remainingToInvest <= underlyingBalanceInVault() // TODO: we think that the "else" branch of the ternary operation is not
                    ? // going to get hit
                    remainingToInvest
                    : underlyingBalanceInVault();
        }
    }

    function maxDeposit(
        address /*caller*/
    ) public pure override returns (uint256) {
        return uint(0); // -1
    }

    function _transferAndMint(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(asset()),msg.sender, address(this), assets);

        _afterDepositHook(assets, shares, receiver, fromDeposit);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * Called be the `deposit` and `mint` functions after the assets have been transferred into the vault
     * but before shares are minted.
     * Typically, the hook implementation deposits the assets into the underlying vaults or platforms.
     *
     * @dev the shares returned from `totalSupply` and `balanceOf` have not yet been updated with the minted shares.
     * The assets returned from `totalAssets` and `assetsOf` are typically updated as part of the `_afterDepositHook` hook but it depends on the implementation.
     *
     * If an vault is implementing multiple vault capabilities, the `_afterDepositHook` function that updates the assets amounts should be executed last.
     *
     * @param assets the amount of underlying assets to be transferred to the vault.
     * @param shares the amount of vault shares to be minted.
     * @param receiver the account that is receiving the minted shares.
     */
    function _afterDepositHook(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {}


    // ========================= Conversion Functions =========================

    function convertToAssets(
        uint256 _shares
    ) public view override returns (uint256) {
        console.log('convertToAssets');
        console.log('shares %s', _shares);
        console.log('totalAssets %s', totalAssets());
        console.log('totalSupply %s', totalSupply());
        
        return
            totalAssets() == 0 || totalSupply() == 0 || _shares ==0
                ? (_shares *
                    (TEN ** ERC20Upgradeable(underlying()).decimals())) /
                    (TEN ** decimals())
                : (_shares * totalAssets()) / totalSupply();
    }

    // =========================== SETTERS ===========================
    function setStrategy(address _strategy) external onlyAdmin {
        require(_strategy != address(0), "Zero address not allowed");
        strategy = IStrategy(_strategy);
        //  emit Mark2MarketUpdated(_mark2market);
    }

    function setUnderlyingAsset(address newUnderlying) external  onlyAdmin {
        //require(underlyingBalanceWithInvestment() == 0, "balance must be zero");
        _setUnderlyingAsset(newUnderlying);
       // ERC20Upgradeable(newUnderlying).approve(address(strategy),0);
        //ERC20Upgradeable(newUnderlying).approve(address(strategy), uint256(2**(256) - 1));
    }

    function setVault(IVault _vault) external onlyAdmin {
        require(address(vault) == address(0), "Vault already set");
        vault = _vault;
    }


    // =========================== INTERNAL FUNCTIONS ===========================

    // =========================== REWARDS STREAMING ===========================

    function claim() updateReward(msg.sender) public {
        _claimTokenReward(msg.sender);
    }

    function claimWithBeneficiary(address _beneficiary) updateReward(msg.sender) public {
        _claimTokenReward(_beneficiary);
    }
    /**
     * @dev Credits any outstanding rewards to the sender
     */
    function _claimTokenReward(address claiment) internal returns (uint256) {
        uint256 reward = rewards[claiment];
        if (reward > 0) {
            console.log('sending reward of %s', reward);
            rewards[claiment] = 0;
            IERC20(asset()).transfer(claiment, reward);
        }
        return reward;
    }

     /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    // Updated function name to avoid conflict
        function stake(uint256 _amount) public {
            _stake(msg.sender, _amount);
        }

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stakeWithBeneficiary(address _beneficiary, uint256 _amount)  public {
        console.log('stake w/ beneficiary');
        console.log('_beneficiary %s', _beneficiary);
        console.log('_amount %s', _amount);
        _stake(_beneficiary, _amount);
    }


   /**
     * @dev Internally stakes an amount by depositing from sender,
     * and crediting to the specified beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function _stake(address _beneficiary, uint256 _amount)
        internal
        updateReward(_beneficiary)
    {
        require(_amount > 0, "Cannot stake 0");
       // super._stake(_beneficiary, _amount);  /// THIS WOULD BE THE STAKING TOKEN WRAPPER
        /* CODE FROM the super_stake */
         _totalSupply = _totalSupply + _amount;
        _balances[_beneficiary] = _balances[_beneficiary] + _amount;
        console.log('transfering amount: %s from %s to %s', _amount, address(this), msg.sender);
        console.log('balance of streamvault: %s', IERC20Upgradeable(asset()).balanceOf(address(this)));
        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), _amount);

        emit Transfer(address(0), _beneficiary, _amount);
        /* END CODE FROM the super_stake */
        emit Staked(_beneficiary, _amount, msg.sender);
    }

    function exitWithBeneficiary(address _beneficiary) public updateReward(_beneficiary) {
         uint256 amount = balanceOf(_beneficiary);
        _withdraw(_beneficiary, amount);
        emit Withdrawn(_beneficiary, amount);
        _claimTokenReward(_beneficiary);
    }

    /**
     * @dev Withdraws stake from pool and claims any rewards
     */
    function exit() public updateReward(msg.sender) {
        uint256 amount = balanceOf(msg.sender);
        _withdraw(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
        _claimTokenReward(msg.sender);
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
        console.log('in rewardPerToken stakedTokens %s', stakedTokens);
        if (stakedTokens == 0) {
            return (rewardPerTokenStored);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e9) / totalTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
       
        // return summed rate
        return (
            rewardPerTokenStored + unitsToDistributePerToken
        );
    }

    function notifyRewardAmount (uint256 _reward) external onlyAdmin {
        console.log('notifyRewardAmount %s', _reward);
        _notifyRewardAmount(_reward);
    }

        /**
     * @dev Get the balance of a given account
     * @param _account User for which to retrieve balance
     */
    function balanceOf(address _account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
       //return _balances[_account];
        return vault.underlyingBalanceWithInvestmentForHolder(_account);
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
       //return _totalSupply;
       return vault.totalAssets();
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
        console.log('currentTime %s and periodFinish %s', currentTime,periodFinish);
        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            rewardRate = _reward / DURATION;
            console.log('NEW rewardRate %s', rewardRate);
          //  platformRewardRate = newPlatformRewards / DURATION;
        }
        // If additional reward to existing period, calc sum
        else {
            console.log('still in current reward period');
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * rewardRate;
            rewardRate = (_reward + leftoverReward) / DURATION;
            console.log('NEW rewardRate %s', rewardRate);

            //uint256 leftoverPlatformReward = remaining * platformRewardRate;
       //     platformRewardRate = (newPlatformRewards + leftoverPlatformReward) / DURATION;
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime + DURATION;

        emit RewardAdded(_reward,0);
    }
   
    /**
     * 
     * 
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        _withdraw(msg.sender,_amount);
        _claimTokenReward(msg.sender);
        emit Withdrawn(msg.sender, _amount);
    }

  /**
     * @dev Withdraws a given stake from sender
     * @param _amount Units of StakingToken
     */
    function _withdraw(address caller, uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[caller] >= _amount, "Not enough user rewards");
        _totalSupply = _totalSupply - _amount;
        _balances[caller] = _balances[caller] - _amount;
        IERC20Upgradeable(asset()).safeTransfer(caller, _amount);

        emit Transfer(caller, address(0), _amount);
    }

    /**
     * 
     * 
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdrawWithBeneficiary(uint256 _amount) external updateReward(msg.sender) {
        _withdraw(msg.sender, _amount);
        _claimTokenReward(msg.sender);
        emit Withdrawn(msg.sender, _amount);
    }


    function _setUnderlyingAsset(address newUnderlying) internal {
        console.log("newUnderlying", newUnderlying);
        _underlying = newUnderlying;
        _underlyingUnit = 10 ** uint256(ERC20Upgradeable(newUnderlying).decimals());
    }
}
