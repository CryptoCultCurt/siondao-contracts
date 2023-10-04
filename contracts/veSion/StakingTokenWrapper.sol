// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract StakingTokenWrapper is ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    IERC20Upgradeable public immutable stakingToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
     * @dev TokenWrapper constructor
     * @param _stakingToken Wrapped token to be staked
     */
    constructor(address _stakingToken) {
        stakingToken = IERC20Upgradeable(_stakingToken);
    }

    function _initialize(string memory _nameArg, string memory _symbolArg) internal {
       // _initializeReentrancyGuard();
        __ReentrancyGuard_init();
        name = _nameArg;
        symbol = _symbolArg;
    }

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
     * @dev Deposits a given amount of StakingToken from sender
     * @param _amount Units of StakingToken
     */
    function _stake(address _beneficiary, uint256 _amount) internal virtual nonReentrant {
        _totalSupply = _totalSupply + _amount;
        _balances[_beneficiary] = _balances[_beneficiary] + _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Transfer(address(0), _beneficiary, _amount);
    }

    /**
     * @dev Withdraws a given stake from sender
     * @param _amount Units of StakingToken
     */
    function _withdraw(uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount, "Not enough user rewards");
        _totalSupply = _totalSupply - _amount;
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        stakingToken.safeTransfer(msg.sender, _amount);

        emit Transfer(msg.sender, address(0), _amount);
    }

    /**
     * @dev Reduced a given staked balance of sender (no transfer)
     * @param _amount Units of StakingToken
     */
    function _reduceRaw(uint256 _amount) internal nonReentrant {
        require(_balances[msg.sender] >= _amount, "Not enough user rewards");
        _totalSupply = _totalSupply - _amount;
        _balances[msg.sender] -= _amount;
    }
}