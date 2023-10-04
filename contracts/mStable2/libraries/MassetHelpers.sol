// SPDX-License-Identifier: AGPL-3.0-or-later
// Internal
// Libs

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";



library MassetHelpers {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function transferReturnBalance(
        address _sender,
        address _recipient,
        address _bAsset,
        uint256 _qty
    ) internal returns (uint256 receivedQty, uint256 recipientBalance) {
        uint256 balBefore = IERC20Upgradeable(_bAsset).balanceOf(_recipient);
        IERC20Upgradeable(_bAsset).safeTransferFrom(_sender, _recipient, _qty);
        recipientBalance = IERC20Upgradeable(_bAsset).balanceOf(_recipient);
        receivedQty = recipientBalance - balBefore;
    }

    function safeInfiniteApprove(address _asset, address _spender) internal {
        IERC20Upgradeable(_asset).safeApprove(_spender, 0);
        IERC20Upgradeable(_asset).safeApprove(_spender, 2**256 - 1);
    }
}