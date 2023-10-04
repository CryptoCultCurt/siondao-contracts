// SPDX-License-Identifier: AGPL-3.0-or-later
// Internal
// Libs

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


interface ISavingsContractV3 {
    function redeemAndUnwrap(
        uint256 _amount,
        bool _isCreditAmt,
        uint256 _minAmountOut,
        address _output,
        address _beneficiary,
        address _router,
        bool _isBassetOut
    )
        external
        returns (
            uint256 creditsBurned,
            uint256 massetRedeemed,
            uint256 outputQuantity
        );

    function depositSavings(
        uint256 _underlying,
        address _beneficiary,
        address _referrer
    ) external returns (uint256 creditsIssued);
}