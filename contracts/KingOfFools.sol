// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KingOfFools is Ownable, ReentrancyGuard {
    AggregatorV3Interface internal _priceFeed;
    mapping(address => uint256) public balanceInUsdOf;
    address[] private _users;

    constructor(address priceFeedAddress) {
        _priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function getLatestETHPrice() public view returns (int256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        return price;
    }

    function changePriceFeedAddress(address newAddress) external onlyOwner {
        _priceFeed = AggregatorV3Interface(newAddress);
    }

    function depositETH() external payable nonReentrant {
        address currentUser = _currentKing();
        int256 ethPrice = getLatestETHPrice();
        uint256 amount = msg.value * uint256(ethPrice);

        require(
            amount >= (balanceInUsdOf[currentUser] * 150) / 100,
            "KingOfFools: insufficient amount"
        );

        // update storage
        _users.push(msg.sender);
        balanceInUsdOf[currentUser] = amount;
        // transfer money to the last user
        if (currentUser != address(0)) {
            (bool sent, ) = currentUser.call{value: msg.value}("");
            require(sent, "KingOfFools: failed to transfer ETH to last king");
        }
    }

    function depositToken(IERC20 token, uint256 amount)
        external
        payable
        nonReentrant
    {
        address currentUser = _currentKing();

        require(
            amount >= (balanceInUsdOf[currentUser] * 150) / 100,
            "KingOfFools: insufficient amount"
        );

        _users.push(msg.sender);
        balanceInUsdOf[currentUser] = amount;

        if (currentUser != address(0)) {
            bool sent = token.transferFrom(msg.sender, currentUser, amount);

            require(sent, "KingOfFools: transfer failed");
        }
    }

    function currentKing() external view returns (address) {
        return _currentKing();
    }

    function currentKingBalance() external view returns (uint256) {
        return balanceInUsdOf[_currentKing()];
    }

    function _currentKing() private view returns (address) {
        uint256 numUsers = _users.length;

        return numUsers == 0 ? address(0) : _users[numUsers - 1];
    }
}
