//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interface/IUniversalLiquidator.sol";
import "./interface/IVault.sol";
import "./interface/ICaviarChef.sol";
import "./interface/IRewardForwarder.sol";

import "hardhat/console.sol";

contract CaviarStrategy is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public onlyVault {
        address _underlying = underlying;
        uint256 balanceBefore = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        _claimReward();
        uint256 balanceAfter = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        uint256 claimedUnderlying = balanceAfter.sub(balanceBefore);
        _withdrawUnderlyingFromPool(_rewardPoolBalance());
        _liquidateReward(claimedUnderlying);
        address underlying_ = underlying;
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


    function doHardWork() external onlyVault { // we don't want to call this directly as the vault must first transfer the funds to the strategy
        address _underlying = underlying;
        uint256 balanceBefore = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        _claimReward();
        uint256 balanceAfter = IERC20Upgradeable(_underlying).balanceOf(
            address(this)
        );
        _investAllunderlying();
        console.log("invested");
        console.log("balance before", balanceBefore);
        console.log("balance after", balanceAfter);
        uint256 claimedUnderlying = balanceAfter.sub(balanceBefore);
        console.log("claimed rewards", claimedUnderlying);
        _liquidateReward(claimedUnderlying);
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


    function _liquidateReward(uint256 amountUnderlying) internal {
        // if (!sell()) {
        //   // Profits can be disabled for possible simplified and rapid exit
        //   emit ProfitsNotCollected(sell(), false);
        //   return;
        // }
        address _rewardToken = rewardToken;
        address _underlying = underlying;
        address _universalLiquidator = universalLiquidator;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            console.log('liquidating REWARD token', token);
            uint256 rewards;
            if (token == _underlying) {
                rewards = amountUnderlying;
            } else {
                rewards = IERC20Upgradeable(token).balanceOf(address(this));
            }
            if (rewards == 0) {
                console.log("no rewards for token", token);
                continue;
            }
            if (token != _rewardToken) {
                console.log("approving REWARD ", token, "for liquidation");
                console.log(
                    "swapping REWARD %s %s for %s",
                    rewards,
                    token,
                    _rewardToken
                );
                console.log("universal liquidator", _universalLiquidator);
                IERC20Upgradeable(token).safeApprove(_universalLiquidator, 0);
                IERC20Upgradeable(token).safeApprove(
                    _universalLiquidator,
                    rewards
                );
                IUniversalLiquidator(_universalLiquidator).swap(
                    token,
                    _rewardToken,
                    rewards,
                    1,
                    address(this)
                );
                console.log('swapped token %s for %s', token, _rewardToken);
            }
        }

        uint256 rewardBalance = IERC20Upgradeable(_rewardToken).balanceOf(
            address(this)
        );
        console.log("notifying profit", _rewardToken, rewardBalance);
        _notifyProfitInRewardToken(_rewardToken, rewardBalance);
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
