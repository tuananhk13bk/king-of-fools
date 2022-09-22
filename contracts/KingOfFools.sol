// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KingOfFools is Ownable {
    AggregatorV3Interface internal _priceFeed;
    mapping(address => uint256) public balanceInUsdOf;
    address[] private _users;

    modifier ensureValidAmount(uint256 _amount, bool isEthAmount) {
        uint256 amount = _amount;
        if (isEthAmount) {
            int256 ethPrice = getLatestETHPrice();
            amount = _amount * uint256(ethPrice);
        }

        require(
            amount >= balanceInUsdOf[_currentKing()],
            "KingOfFools: invalid amount"
        );
        _;
    }

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

    function depositETH() external payable ensureValidAmount(msg.value, true) {
        address currentUser = _currentKing();

        address recipient = currentUser == address(0)
            ? address(this)
            : currentUser;

        // update storage
        _users.push(msg.sender);
        balanceInUsdOf[currentUser] = msg.value;
        // transfer money to the last user
        (bool sent, ) = recipient.call{value: msg.value}("");

        require(sent, "KingOfFools: failed to transfer ETH to last king");
    }

    function depositToken(IERC20 token, uint256 amount)
        external
        payable
        ensureValidAmount(amount, false)
    {}

    function test() public {}

    function withdraw() external onlyOwner {}

    function withdrawToken(IERC20 token) external onlyOwner {}

    function currentKing() external view returns (address) {
        return _currentKing();
    }

    function currentKingBalance() external view returns (uint256) {
        return balanceInUsdOf[_currentKing()];
    }

    function _currentKing() private view returns (address) {
        uint256 numUsers = _users.length;

        return _users[numUsers - 1];
    }
}
