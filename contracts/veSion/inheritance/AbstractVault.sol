// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../interface/IRewardsVault.sol"; // the vault rewards are claimed from
import "../interface/IVaultManager.sol"; // handles deposits and sending to strategies
import "../interface/IMark2Market.sol"; // gets current market value of assets

import "hardhat/console.sol";

contract AbstractVault is
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC4626Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    /// @notice Address of the vault's underlying asset token.
    // IERC20Upgradeable internal immutable _asset;
    IERC20Upgradeable private _asset;
    IRewardsVault public rewardsVault;
    IVaultManager public vaultManager;
    IMark2Market public mark2Market;

    // ---  events

    event VaultManagerUpdated(address value);
    event Mark2MarketUpdated(address value);
    event RewardsVaultUpdated(address value);

    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    // modifier onlyExchanger() {
    //     require(hasRole(EXCHANGER, msg.sender), "Caller is not the EXCHANGER");
    //     _;
    // }

    // modifier onlyPortfolioAgent() {
    //     require(hasRole(PORTFOLIO_AGENT_ROLE, msg.sender), "Restricted to Portfolio Agent");
    //     _;
    // }

    // constructor(address _assetArg) {
    //     require(_assetArg != address(0), "Asset is zero");
    //     _asset = IERC20Upgradeable(_assetArg);
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

    // /**
    //  * @param _assetToBurn amount of assets that will be deposited and corresponding shares locked permanently
    //  * @dev This is to prevent against loss of precision and frontrunning the user deposits by sandwitch attack. Should be a non-trivial amount
    //  */
    function _initialize(IERC20Upgradeable underlyingasset) internal virtual {
       _asset = underlyingasset;
    }

    // Custom functions for Sion
    // These will need to be redone to correctly work with the M2M

    function underlyingBalanceInVault() public view returns (uint256) {
        return totalAssets();
    }

    //     // /* Returns the current underlying (e.g., DAI's) balance together with
    //     //  * the invested amount (if DAI is invested elsewhere by the strategy).
    //     //  */
    function underlyingBalanceWithInvestment() public view returns (uint256) {
        return underlyingBalanceInVault();
    }

    function deposit(uint256 amount, address receiver) override public returns (uint256)  {
        uint256 minted = _deposit(amount, msg.sender, receiver);
        return minted;
    }

    function _deposit(
        uint256 amount,
        address sender,
        address beneficiary
    ) internal returns (uint256) {
        require(amount > 0, "Cannot deposit 0");
        require(beneficiary != address(0), "holder must be defined");

        uint256 toMint = totalSupply() == 0
            ? amount
            : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
        _mint(beneficiary, toMint);
        console.log("successful mint");
        console.log("transfering %s of token %s", amount, asset());
        console.log("from %s", sender);
        console.log("to %s", address(vaultManager));
        IERC20Upgradeable(asset()).safeTransferFrom(
            sender,
            address(vaultManager),
            amount
        );
        console.log("successful transfer");
        console.log("depositing to vault manager (%s)", address(vaultManager));
        vaultManager.deposit(); // tell the vault manager to deal with the deposit
        console.log("successful deposit to vaultManager");
        // update the contribution amount for the beneficiary
        emit Deposit(sender, beneficiary, amount, toMint);
        _afterDepositHook(amount, toMint, beneficiary, true);
        return toMint;
    }

    function asset() public view override returns (address) {
        return address(_asset);
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

    // SETTERS
    function setVaultManager(address _value) external onlyAdmin {
        require(_value != address(0), "Zero address not allowed");
        vaultManager = IVaultManager(_value);
        emit VaultManagerUpdated(_value);
    }

    function setRewardsVault(address _value) external onlyAdmin {
        require(_value != address(0), "Zero address not allowed");
        rewardsVault = IRewardsVault(_value);
        emit RewardsVaultUpdated(_value);
    }

    function setMark2Market(address _value) external onlyAdmin {
        require(_value != address(0), "Zero address not allowed");
        mark2Market = IMark2Market(_value);
        emit Mark2MarketUpdated(_value);
    }
}
