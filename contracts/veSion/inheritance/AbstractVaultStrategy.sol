// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import { IERC20Upgradeable }  from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libs
import { ILiquidatorVault } from "../interface/ILiquidatorVault.sol";
import { IERC4626Vault } from "../interface/IERC4626Vault.sol";

/**
 * @title   Vaults must implement this if they integrate to the Liquidator.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 *
 * Implementations must implement the `collectRewards` function.
 *
 */

                                            
abstract contract AbstractVaultStrategy is IERC4626Vault, ILiquidatorVault, PausableUpgradeable, AccessControlUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant EXCHANGER = keccak256("EXCHANGER");
    bytes32 public constant PORTFOLIO_AGENT_ROLE = keccak256("PORTFOLIO_AGENT_ROLE");
    uint256 public constant TOTAL_WEIGHT = 100000; // 100000 ~ 100%

    // ---  fields
      /// @notice Reward tokens collected by the vault.
    address[] public rewardToken;
    address public universalLiquidator;
    IERC20Upgradeable private _asset;
   

    // ---  events

    event RewardAdded(address indexed reward, uint256 position);


    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    modifier onlyExchanger() {
        require(hasRole(EXCHANGER, msg.sender), "Caller is not the EXCHANGER");
        _;
    }

    modifier onlyPortfolioAgent() {
        require(hasRole(PORTFOLIO_AGENT_ROLE, msg.sender), "Restricted to Portfolio Agent");
        _;
    }

    // ---  constructor


    function _initialize() internal virtual {
    }


    ////
 // ---  modifiers

   

    /**
     * Collects reward tokens from underlying platforms or vaults to this vault and
     * reports to the caller the amount of tokens now held by the vault.
     * This can be called by anyone but it used by the Liquidator to transfer the
     * rewards tokens from this vault to the liquidator.
     *
     * @param rewardTokens_ Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param donateTokens The token the Liquidator swaps the reward tokens to.
     */
    function collectRewards()
        external
        virtual
        override
        returns (
            address[] memory rewardTokens_,
            uint256[] memory rewards,
            address[] memory donateTokens
        )
    {
        _beforeCollectRewards();

        uint256 rewardLen = rewardToken.length;
        rewardTokens_ = new address[](rewardLen);
        rewards = new uint256[](rewardLen);
        donateTokens = new address[](rewardLen);

        for (uint256 i; i < rewardLen; ) {
            address rewardTokenMem = rewardToken[i];
            rewardTokens_[i] = rewardTokenMem;
            // Get reward token balance for this vault.
            rewards[i] = IERC20Upgradeable(rewardTokenMem).balanceOf(address(this));
            donateTokens[i] = _donateToken(rewardTokenMem);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Base implementation doesn't do anything.
     * This can be overridden to get rewards from underlying platforms or vaults.
     */
    function _beforeCollectRewards() internal virtual {
        // Do nothing
    }

    /**
     * @dev Tells the Liquidator what token to swap the reward tokens to.
     * For example, the vault asset.
     * @param reward Reward token that is being sold by the Liquidator.
     */
    function _donateToken(address reward) internal view virtual returns (address token);

    /**
     * @notice Adds new reward tokens to the vault so the liquidator module can transfer them from the vault.
     * Can only be called by the protocol governor.
     * @param _rewardTokens A list of reward token addresses.
     */
    function addRewards(address[] memory _rewardTokens) external virtual onlyAdmin {
        _addRewards(_rewardTokens);
    }

    function _addRewards(address[] memory _rewardTokens) internal virtual {
        address liquidator = universalLiquidator;
        require(liquidator != address(0), "invalid Liquidator V2");

        uint256 rewardTokenLen = rewardToken.length;

        // For reward token
        uint256 len = _rewardTokens.length;
        for (uint256 i; i < len; ) {
            address newReward = _rewardTokens[i];
            rewardToken.push(newReward);
            IERC20Upgradeable(newReward).safeApprove(liquidator, type(uint256).max);

            emit RewardAdded(newReward, rewardTokenLen + i);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns all reward tokens address added to the vault.
     */
    function rewardTokens() external view override returns (address[] memory) {
        return rewardToken;
    }

    /**
     * @notice Returns the token that rewards must be swapped to before donating back to the vault.
     * @param _rewardToken The address of the reward token collected by the vault.
     * @return token The address of the token that `_rewardToken` is to be swapped for.
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     */
    function donateToken(address _rewardToken) external view override returns (address token) {
        token = _donateToken(_rewardToken);
    }

    function setUniversalLiquidator(address _address) public onlyAdmin {
        universalLiquidator = _address;
    }

    // standard ERC4626 Vault functions
     /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    function _deposit(uint256 assets, address receiver) internal virtual returns (uint256 shares) {
        shares = _previewDeposit(assets);

        _transferAndMint(assets, shares, receiver, true);
    }

    function previewDeposit(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewDeposit(assets);
    }

    function _previewDeposit(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets, false);
    }

    function maxDeposit(address caller) external view override returns (uint256 maxAssets) {
        maxAssets = _maxDeposit(caller);
    }

    function _maxDeposit(address) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = type(uint256).max;
    }

    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    function _mint(uint256 shares, address receiver) internal virtual returns (uint256 assets) {
        assets = _previewMint(shares);
        _transferAndMint(assets, shares, receiver, false);
    }

    function previewMint(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewMint(shares);
    }

    function _previewMint(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares, true);
    }

    function maxMint(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxMint(owner);
    }

    function _maxMint(address) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }

        maxShares = type(uint256).max;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL DEPSOIT/MINT
    //////////////////////////////////////////////////////////////*/

    function _transferAndMint(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        _afterDepositHook(assets, shares, receiver, fromDeposit);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override(IERC4626Vault, ILiquidatorVault) whenNotPaused returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }

    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual returns (uint256 shares) {
        shares = _previewWithdraw(assets);

        _burnTransfer(assets, shares, receiver, owner, false);
    }

    function previewWithdraw(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewWithdraw(assets);
    }

    function _previewWithdraw(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets, true);
    }

    function maxWithdraw(address owner) external view override returns (uint256 maxAssets) {
        maxAssets = _maxWithdraw(owner);
    }

    function _maxWithdraw(address owner) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = _previewRedeem(balanceOf(owner));
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual returns (uint256 assets) {
        assets = _previewRedeem(shares);
        _burnTransfer(assets, shares, receiver, owner, true);
    }

    function previewRedeem(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewRedeem(shares);
    }

    function _previewRedeem(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares, false);
    }

    function maxRedeem(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxRedeem(owner);
    }

    function _maxRedeem(address owner) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }
        
        maxShares = balanceOf(owner);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function _burnTransfer(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner,
        bool fromRedeem
    ) internal virtual {
        // If caller is not the owner of the shares
        uint256 allowed = allowance(owner, msg.sender);
        if (msg.sender != owner && allowed != type(uint256).max) {
            require(shares <= allowed, "Amount exceeds allowance");
            _approve(owner, msg.sender, allowed - shares);
        }
        _beforeWithdrawHook(assets, shares, owner, fromRedeem);

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                            EXTENRAL ASSETS
    //////////////////////////////////////////////////////////////*/

    function asset() external view virtual override returns (address assetTokenAddress) {
        assetTokenAddress = address(_asset);
    }

    /**
     * @notice It should include any compounding that occurs from yield. It must be inclusive of any fees that are charged against assets in the Vault. It must not revert.
     *
     * Returns the total amount of the underlying asset that is “managed” by vault.
     */
    function totalAssets() public view virtual override(IERC4626Vault, ILiquidatorVault) returns (uint256 totalManagedAssets);

    function netAssets() external view virtual returns (uint256 netAssetsAmount) {
        netAssetsAmount = totalAssets();
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
     * @param shares The amount of vault shares to be converted to the underlying assets.
     * @return assets The amount of underlying assets converted from the vault shares.
     */
    function convertToAssets(uint256 shares)
        external
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = _convertToAssets(shares, false);
    }

    /// @param shares The amount of vault shares to be converted to the underlying assets.
    /// @param isRoundUp bool to indicate round up the assets
    /// @dev isRoundUp is used to round-up the assets amount for mint and previewMint
    function _convertToAssets(uint256 shares, bool isRoundUp) internal view virtual returns (uint256 assets) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            assets = shares; // 1:1 value of shares and assets
        } else {
            uint256 totalAssetsMem = totalAssets();
            assets = (shares * totalAssetsMem) / totalShares;

            // Round Up if needed
            if(isRoundUp && mulmod(shares, totalAssetsMem, totalShares) > 0) {
                assets += 1;
            }
        }
    }

    /**
     * @notice The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
     * @param assets The amount of underlying assets to be convert to vault shares.
     * @return shares The amount of vault shares converted from the underlying assets.
     */
    function convertToShares(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = _convertToShares(assets, false);
    }

    /// @param assets The amount of underlying assets to be convert to vault shares.
    /// @param isRoundUp bool to indicate round up the shares
    /// @dev isRoundUp is used to round-up the shares amount for withdraw and previewWithdraw
    function _convertToShares(uint256 assets, bool isRoundUp) internal view virtual returns (uint256 shares) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            shares = assets; // 1:1 value of shares and assets
        } else {
            uint256 totalAssetsMem = totalAssets();
            shares = (assets * totalShares) / totalAssetsMem;

            // Round Up if needed
            if (isRoundUp && mulmod(assets, totalShares, totalAssetsMem) > 0) {
                shares += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

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

    /**
     * Called be the `withdraw` and `redeem` functions before
     * the assets have been transferred from the vault to the receiver
     * and before the owner's shares are burnt.
     * Typically, the hook implementation withdraws the assets from the underlying vaults or platforms.
     *
     * @param assets the amount of underlying assets to be withdrawn from the vault.
     * @param shares the amount of vault shares to be burnt.
     * @param owner the account that owns the shares that are being burnt.
     */
    function _beforeWithdrawHook(
        uint256 assets,
        uint256 shares,
        address owner,
        bool fromRedeem
    ) internal virtual {}
}
