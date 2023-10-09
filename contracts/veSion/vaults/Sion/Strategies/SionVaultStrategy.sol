// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AbstractVaultStrategy } from "../../../inheritance/AbstractVaultStrategy.sol";
import { IERC20Upgradeable }  from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../../../../interfaces/IExchange.sol";
import "../../../interface/IUniversalLiquidator.sol";
import "../../../interface/IVault.sol";
import "hardhat/console.sol";

contract SionVaultStrategy is AbstractVaultStrategy {
    IERC20Upgradeable private _asset;
    IERC20Upgradeable public cvr;

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
    }

    function netAssetValue() public view returns(uint256) {
        return _totalValue(false);
    }


    function _totalValue(bool nav) internal view returns (uint256) {
        console.log('getting total value of asset ', address(_asset));
        uint256 sionBalance = _asset.balanceOf(address(this));
        console.log('sion balance from strategy: ', sionBalance);

        return sionBalance;
    }

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
            rewards[i] = IERC20Upgradeable(rewardTokenMem).balanceOf(
                address(this)
            );
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
    function _beforeCollectRewards() internal override {
        // Do nothing
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function donate(address token, uint256 amount) external override {}

    function _donateToken(
        address reward
    ) internal view virtual override returns (address token) {}

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }

    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal override returns (uint256 shares) {
        shares = _previewWithdraw(assets);

        _burnTransfer(assets, shares, receiver, owner, false);
    }

    function totalAssets()
        public
        view
        override
        returns (uint256 totalManagedAssets)
    {}

    // function underlyingBalanceInVault()
    //     external
    //     view
    //     override
    //     returns (uint256)
    // {}

    // function underlyingBalanceWithInvestment()
    //     external
    //     view
    //     override
    //     returns (uint256)
    // {}

    // function underlying() external view override returns (address) {}

    // function strategy() external view override returns (address) {}

    // function setStrategy(address _strategy) external override {}

    // function announceStrategyUpdate(address _strategy) external override {}

    // function setVaultFractionToInvest(
    //     uint256 numerator,
    //     uint256 denominator
    // ) external override {}

    function setCVRToken(address _cvr) external {
        cvr = IERC20Upgradeable(_cvr);
    }

    function deposit(uint256 amountWei, address receiver) external override returns (uint256) {
        console.log('cash strategy deposit called.  currently does nothing');
        // convert sion depositted into usdc through redeem ****** ISSUE: we do NOT want to actually redeem sion here, just convert to usdc
        _asset.approve(address(exchange), amountWei);
        exchange.redeem(address(usdc), amountWei);
        //  we then convert the USDC to CVR which is the underlying token of this vault
        uint256 usdcBalance = usdc.balanceOf(address(this));
        // approve the trasnfer of USDC to the universalLiquidator
        usdc.approve(address(universalLiquidator), usdcBalance);
        universalLiquidator.swap(
                    address(usdc),
                    address(cvr),
                    1000000,
                    0,
                    address(this)
                );
        // then call the deposit function on the CaviarVault
        caviarVault.deposit(amountWei, address(this));
        return amountWei;

    }

    // function depositFor(uint256 amountWei, address holder) external override {}

    // function withdrawAll() external override {}

    // function getPricePerFullShare() external view override returns (uint256) {}

    // function underlyingBalanceWithInvestmentForHolder(
    //     address holder
    // ) external view override returns (uint256) {}

    // function doHardWork() external override {}

    // function liquidationValue() external view override returns (uint256) {}
}