// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC20Upgradeable }  from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AbstractVault } from "../../inheritance/AbstractVault.sol";
import "../../interface/IRewardsVault.sol";
import "../../interface/IVaultManager.sol";
import "../../interface/IMark2Market.sol";

import "hardhat/console.sol";

contract SionVault is AbstractVault {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable private _asset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _assetArg
    ) external initializer {
        // Set the vault's decimals to the same as the reference asset.
        // uint8 _decimals = InitializableToken(address(_asset)).decimals();
        // InitializableToken._initialize(_nameArg, _symbolArg, _decimals);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __ERC20_init(_nameArg, _symbolArg);
        _asset = IERC20Upgradeable(_assetArg);
        AbstractVault._initialize(IERC20Upgradeable(_assetArg));
    }

        // function setStrategy(address _strategy) external virtual override {
        //     require(_strategy != address(0), "Zero address not allowed");
        //    // strategy = IStrategy(_strategy);
        //     //  emit Mark2MarketUpdated(_mark2market);
        // }
        // function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external virtual override;
        // function setRewardsVault(address _rewardsVault) external virtual override;
        // function setVaultManager(address _vaultManager) external virtual override;
        // function setMark2Market(address _m2m) external virtual override;

    // function _authorizeUpgrade(
    //     address newImplementation
    // ) internal virtual override {}

    //     uint256 private _underlyingUnit;
    //     address private _underlying;
    //     uint256 private _vaultFractionToInvestNumerator;
    //     uint256 private _vaultFractionToInvestDenominator;
    //   //  IStrategy public strategy;
    //     uint256 public constant TEN = 10; // This implicitly converts it to `uint256` from uint8

    //     IRewardsVault public rewardsVault; // address of the vault distributing rewards
    //     IVaultManager public vaultManager; // address of the vault manager
    //     IMark2Market public m2m; // address of the mark to market contract

    //     event Invest(uint256 amount);
    //     event StrategyAnnounced(address newStrategy, uint256 time);
    //     event StrategyChanged(address newStrategy, address oldStrategy);

    //     /// @custom:oz-upgrades-unsafe-allow constructor
    //     constructor() initializer {}

   
    //     function _authorizeUpgrade(
    //         address newImplementation
    //     ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    //     // ---  modifiers

    //     function balance() public view returns (uint256) {
    //         return totalAssets();
    //     }

    //     function balanceOf(address _depositor) public view  returns (uint256) {
    //         return (totalAssets() * super.balanceOf(_depositor)) / totalSupply();
    //     }

    //     function totalSupply() public view override returns (uint256) {
    //         return super.totalSupply();
    //     }
    

    //     function withdrawAll() external override onlyAdmin  {
    //         //IStrategy(strategy).withdrawAllToVault();
    //     }

    //     // ======================= VIEWS =======================

    //     // function decimals() public  pure override returns (uint8) {
    //     //     return 18;
    //     // }

    //     // function asset() public view override returns (address) {
    //     //     return _underlying;
    //     // }

    //     // function totalAssets() public view override returns (uint256) {
    //     //     return m2m.totalNetAssets();
    //     // }

    //     // function assetsPerShare() public view returns (uint256) {
    //     //     return convertToAssets(TEN ** decimals());
    //     // }

    //     // function assetsOf(address _depositor) public view returns (uint256) {
    //     //     return (totalAssets() * balanceOf(_depositor)) / totalSupply();
    //     // }

    //     // function maxWithdraw(
    //     //     address _caller
    //     // ) public view override returns (uint256) {
    //     //     return assetsOf(_caller);
    //     // }

    //     // function previewWithdraw(
    //     //     uint256 _assets
    //     // ) public view override returns (uint256) {
    //     //     return convertToShares(_assets);
    //     // }

    //     // function maxRedeem(address _caller) public view override returns (uint256) {
    //     //     return balanceOf(_caller);
    //     // }

    //     // function previewRedeem(
    //     //     uint256 _shares
    //     // ) public view override returns (uint256) {
    //     //     return convertToAssets(_shares);
    //     // }

    //     // function getStrategy() public view returns (address) {
    //     //     return address(strategy);
    //     // }

    //     // function underlying() public view returns (address) {
    //     //     return _underlying;
    //     // }

    //     function underlyingUnit() public view returns (uint256) {
    //         return _underlyingUnit;
    //     }

    //     // /*
    //     //  * Returns the cash balance across all users in this contract.
    //     //  */


    //     function getPricePerFullShare() external view returns (uint256) {

    //         console.log('get price per full share');
    //         console.log('underlying unit: ',asset());
    //         console.log('underlying balance w/ investment: ', underlyingBalanceWithInvestment());
    //         console.log('total supply: ', totalSupply());
    //         return
    //             totalSupply() == 0
    //                 ? underlyingUnit()
    //                 : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(
    //                     totalSupply()
    //                 );
    //     }

    //     // /* get the user's share (in underlying)
    //     //  */
    //     // function underlyingBalanceWithInvestmentForHolder(
    //     //     address holder
    //     // ) external view returns (uint256) {
    //     //     if (totalSupply() == 0) {
    //     //         return 0;
    //     //     }
    //     //     return
    //     //         underlyingBalanceWithInvestment().mul(balanceOf(holder)).div(
    //     //             totalSupply()
    //     //         );
    //     // }

    //     // function availableToInvestOut() public view returns (uint256) {
    //     //     uint256 wantInvestInTotal = underlyingBalanceWithInvestment();
    //     //     uint256 alreadyInvested = IStrategy(strategy)
    //     //         .investedUnderlyingBalance();
    //     //     if (alreadyInvested >= wantInvestInTotal) {
    //     //         return 0;
    //     //     } else {
    //     //         uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
    //     //         return
    //     //             remainingToInvest <= underlyingBalanceInVault() // TODO: we think that the "else" branch of the ternary operation is not
    //     //                 ? // going to get hit
    //     //                 remainingToInvest
    //     //                 : underlyingBalanceInVault();
    //     //     }
    //     // }

    //     // function maxDeposit(
    //     //     address /*caller*/
    //     // ) public pure override returns (uint256) {
    //     //     return uint(0); // -1
    //     // }

    //     // function previewDeposit(
    //     //     uint256 _assets
    //     // ) public view override returns (uint256) {
    //     //     return convertToShares(_assets);
    //     // }

    //     // function maxMint(
    //     //     address /*caller*/
    //     // ) public pure override returns (uint256) {
    //     //     return uint(0); //-1
    //     // }

    //     // function previewMint(
    //     //     uint256 _shares
    //     // ) public view override returns (uint256) {
    //     //     return convertToAssets(_shares);
    //     // }

    //     // // ======================= MUTATIVE FUNCTIONS =======================

    //     function deposit(
    //         uint256 _assets,
    //         address _receiver
    //     ) public override returns (uint256) {
    //         uint shares = convertToShares(_assets);
    //        // _deposit(_assets, msg.sender, _receiver);
    //         return shares;
    //     }

    //     // function mint(
    //     //     uint256 _shares,
    //     //     address _receiver
    //     // ) public override returns (uint256) {
    //     //     uint assets = convertToAssets(_shares);
    //     //     _deposit(assets, msg.sender, _receiver);
    //     //     return assets;
    //     // }

    //     function withdraw(
    //         uint256 _assets,
    //         address _receiver,
    //         address _owner
    //     ) public override returns (uint256) {
    //         console.log('withdraw');
    //         uint256 shares = convertToShares(_assets);
    //        // _withdraw(shares, _receiver, _owner);
    //         return shares;
    //     }

    //     // function withdrawShares(uint256 shares) public returns(uint256) {
    //     //     console.log('withdraw shares');
    //     //     _withdraw(shares, msg.sender, msg.sender);
    //     //     return 0;
    //     // }

    //     // function redeem(
    //     //     uint256 _shares,
    //     //     address _receiver,
    //     //     address _owner
    //     // ) public override returns (uint256) {
    //     //     uint256 assets = convertToAssets(_shares);
    //     //     _withdraw(_shares, _receiver, _owner);
    //     //     return assets;
    //     // }

    //     // function depositFor(uint256 amount, address holder) public {
    //     //     _deposit(amount, msg.sender, holder);
    //     // }

    //     // // ========================= Conversion Functions =========================

    //     // function convertToAssets(
    //     //     uint256 _shares
    //     // ) public view override returns (uint256) {
    //     //     console.log('convertToAssets');
    //     //     console.log('shares %s', _shares);
    //     //     console.log('totalAssets %s', totalAssets());
    //     //     console.log('totalSupply %s', totalSupply());

    //     //     return
    //     //         totalAssets() == 0 || totalSupply() == 0
    //     //             ? (_shares *
    //     //                 (TEN ** ERC20Upgradeable(underlying()).decimals())) /
    //     //                 (TEN ** decimals())
    //     //             : (_shares * totalAssets()) / totalSupply();
    //     // }

    //     // function convertToShares(
    //     //     uint256 _assets
    //     // ) public view override returns (uint256) {
    //     //     return
    //     //         totalAssets() == 0 || totalSupply() == 0
    //     //             ? (_assets * (TEN ** decimals())) /
    //     //                 (TEN ** ERC20Upgradeable(underlying()).decimals())
    //     //             : (_assets * totalSupply()) / totalAssets();
    //     // }

    //     // // =========================== RESTRICTED FUNCTIONS ===========================
    //     // /**
    //     //  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
    //     //  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
    //     //  */
    //     // function doHardWork() external whenStrategyDefined onlyAdmin {
    //     //     // ensure that new funds are invested too
    //     //     _invest();
    //     //     IStrategy(strategy).doHardWork();
    //     // }

    //     // function rebalance() external onlyAdmin {
    //     //     withdrawAll();
    //     //     _invest();
    //     // }

    //     // function invest() external onlyAdmin {
    //     //     _invest();
    //     // }

    //     // function sweepToVault() public onlyAdmin whenStrategyDefined {
    //     //     IStrategy(strategy).sweepToVault();
    //     // }

    //     // // =========================== SETTERS ===========================
    //     // function setStrategy(address _strategy) external onlyAdmin {
    //     //     require(_strategy != address(0), "Zero address not allowed");
    //     //     strategy = IStrategy(_strategy);
    //     //     //  emit Mark2MarketUpdated(_mark2market);
    //     // }

    //     // function setUnderlyingAsset(address newUnderlying) external whenStrategyDefined onlyAdmin {
    //     //     //require(underlyingBalanceWithInvestment() == 0, "balance must be zero");
    //     //     _setUnderlyingAsset(newUnderlying);
    //     //     ERC20Upgradeable(newUnderlying).approve(address(strategy),0);
    //     //     ERC20Upgradeable(newUnderlying).approve(address(strategy), uint256(2**(256) - 1));
    //     // }

    //     // function setRewardsVault(address _rewardsVault) external onlyAdmin {
    //     //     require(_rewardsVault != address(0), "Zero address not allowed");
    //     //     rewardsVault = IRewardsVault(_rewardsVault);
    //     // }

    //     // function setVaultManager(address _vaultManager) external onlyAdmin {
    //     //     require(_vaultManager != address(0), "Zero address not allowed");
    //     //     vaultManager = IVaultManager(_vaultManager);
    //     // }

    //     // function setMark2Market(address _mark2market) external onlyAdmin {
    //     //     require(_mark2market != address(0), "Zero address not allowed");
    //     //     m2m = IMark2Market(_mark2market);
    //     // }

    //     // // =========================== INTERNAL FUNCTIONS ===========================

    //     // function _invest() internal whenStrategyDefined {
    //     //     uint256 availableAmount = availableToInvestOut();
    //     //     if (availableAmount > 0) {
    //     //         IERC20Upgradeable(underlying()).safeTransfer(
    //     //             address(strategy),
    //     //             availableAmount
    //     //         );
    //     //         emit Invest(availableAmount);
    //     //     }
    //     // }

        

    //     // // function _withdraw(
    //     // //     uint256 assets,
    //     // //     address receiver,
    //     // //     address owner
    //     // // ) internal returns (uint256 shares) {
    //     // //     shares = previewWithdraw(assets);

    //     // //     _burnTransfer(assets, shares, receiver, owner, false);
    //     // // }

    //     // function _withdraw(
    //     //     uint256 numberOfShares,
    //     //     address receiver,
    //     //     address owner
    //     // ) internal {
    //     //     require(totalSupply() > 0, "Vault has no shares");
    //     //     require(numberOfShares > 0, "numberOfShares must be greater than 0");
    //     //     uint256 totalSupply = totalSupply();
    //     //     address sender = msg.sender;
    //     //     if (sender != owner) {
    //     //         uint256 currentAllowance = allowance(owner, sender);
    //     //         if (currentAllowance != uint(0)) {
    //     //             // -1
    //     //             require(
    //     //                 currentAllowance >= numberOfShares,
    //     //                 "ERC20: transfer amount exceeds allowance"
    //     //             );
    //     //             _approve(owner, sender, currentAllowance - numberOfShares);
    //     //         }
    //     //     }
    //     //     _burn(owner, numberOfShares);

    //     //     uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
    //     //         .mul(numberOfShares)
    //     //         .div(totalSupply);
    //     //     if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
    //     //         // withdraw everything from the strategy to accurately check the share value
    //     //         if (numberOfShares == totalSupply) {
    //     //             IStrategy(strategy).withdrawAllToVault();
    //     //         } else {
    //     //             uint256 missing = underlyingAmountToWithdraw.sub(
    //     //                 underlyingBalanceInVault()
    //     //             );
    //     //             IStrategy(strategy).withdrawToVault(missing);
    //     //         }
    //     //         // recalculate to improve accuracy
    //     //         underlyingAmountToWithdraw = MathUpgradeable.min(
    //     //             underlyingBalanceWithInvestment().mul(numberOfShares).div(
    //     //                 totalSupply
    //     //             ),
    //     //             underlyingBalanceInVault()
    //     //         );
    //     //     }

    //     //     IERC20Upgradeable(underlying()).safeTransfer(
    //     //         receiver,
    //     //         underlyingAmountToWithdraw
    //     //     );

    //     //     // mark the withdrawal in the rewards vault
    //     //     // rewardsVault.withdrawWithBeneficiary(
    //     //     //     msg.sender,
    //     //     //     numberOfShares
    //     //     // );

    //     //     // update the withdrawal amount for the holder
    //     //     emit Withdraw(
    //     //         sender,
    //     //         receiver,
    //     //         owner,
    //     //         underlyingAmountToWithdraw,
    //     //         numberOfShares
    //     //     );
    //     // }

    //     // function _setUnderlyingAsset(address newUnderlying) internal {
    //     //     console.log("newUnderlying", newUnderlying);
    //     //     _underlying = newUnderlying;
    //     //     _underlyingUnit = 10 ** uint256(ERC20Upgradeable(newUnderlying).decimals());
    //     // }

}
