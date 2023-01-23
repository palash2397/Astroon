// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IASTNftSale.sol";
import "./DateTime.sol";

contract ASTTokenRewards is OwnableUpgradeable, ReentrancyGuardUpgradeable, DateTime {
    IASTNftSale public nftContract;
    IERC20Upgradeable public token;
    IASTNftSale public _astNftsale;

    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    struct UserTokenDetails {
        uint256 lastRewardCliamed;
        uint256 totalRewardsClaimed;
        uint256 toClaim;
        mapping(uint256 => uint256) lastClaim;
    }

    mapping(address => UserTokenDetails) internal userTokenDetailsMap;

    mapping(CATEGORY => mapping(uint256 => uint256)) public RewardsMap;

    mapping(uint256 => uint256) tokenLimitPerMonth;
    mapping(uint256 => mapping(uint256 => uint256)) tokenCliamedPerMonth;

    event HoldngRewardsClaimed(
        uint256 tokenId,
        uint256 rewards,
        CATEGORY _category
    );
    event TotalRewardsClaimed(
        uint256 totalRewards,
        uint256 rewardAmount,
        uint256 SoldTokensRewards
    );

    function initialize(
        address _nftaddress,
        address _AstTokenAddr
    )
        public
        initializer
    {
        nftContract = IASTNftSale(_nftaddress);
        token = IERC20Upgradeable(_AstTokenAddr);
        _astNftsale = IASTNftSale(_nftaddress);

        RewardsMap[CATEGORY.BRONZE][1] = 1 * 10 ** 18;
        RewardsMap[CATEGORY.SILVER][1] = 2 * 10 ** 18;
        RewardsMap[CATEGORY.GOLD][1] = 3 * 10 ** 18;
        RewardsMap[CATEGORY.PLATINUM][1] = 4 * 10 ** 18;

        RewardsMap[CATEGORY.BRONZE][2] = 0.5 * 10 ** 18;
        RewardsMap[CATEGORY.SILVER][2] = 1 * 10 ** 18;
        RewardsMap[CATEGORY.GOLD][2] = 1.5 * 10 ** 18;
        RewardsMap[CATEGORY.PLATINUM][2] = 2 * 10 ** 18;

        RewardsMap[CATEGORY.BRONZE][3] = 0.25 * 10 ** 18;
        RewardsMap[CATEGORY.SILVER][3] = 0.5 * 10 ** 18;
        RewardsMap[CATEGORY.GOLD][3] = 0.75 * 10 ** 18;
        RewardsMap[CATEGORY.PLATINUM][3] = 1 * 10 ** 18;

        tokenLimitPerMonth[2] = 100 * 10 ** 18;
        tokenLimitPerMonth[3] = 200 * 10 ** 18;
        tokenLimitPerMonth[4] = 300 * 10 ** 18;
        tokenLimitPerMonth[5] = 300 * 10 ** 18;
        tokenLimitPerMonth[6] = 750 * 10 ** 18;
        tokenLimitPerMonth[7] = 750 * 10 ** 18;
        tokenLimitPerMonth[8] = 750 * 10 ** 18;
        tokenLimitPerMonth[9] = 750 * 10 ** 18;
        tokenLimitPerMonth[10] = 1500 * 10 ** 18;
        tokenLimitPerMonth[11] = 1500 * 10 ** 18;
        tokenLimitPerMonth[12] = 2500 * 10 ** 18;

        __Ownable_init();
    }

    function setTokenLimit(
        uint256 month,
        uint256 amount
    )
        external
        onlyOwner
    {
        tokenLimitPerMonth[month] = amount;
    }

    function claim()
        external
        nonReentrant
    {
        address user = msg.sender;
        uint256 rewards;
        uint256 nftBalance = nftContract.balanceOf(user);
        UserTokenDetails storage userDetails = userTokenDetailsMap[msg.sender];
        for (uint256 i; i < nftBalance; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(user, i);
            uint8 x = uint8(nftContract.getCategory(id));
            uint256 amount = getRewardsCalc(x, id, user);
            userDetails.lastClaim[id] = block.timestamp;
            rewards += amount;
            emit HoldngRewardsClaimed(id, rewards, CATEGORY(x));
        }
        uint256 claimedRewards = rewards + userDetails.toClaim;
        (uint256 month, uint256 year) = getMonthAndYear();
        require(tokenCliamedPerMonth[year][month] + claimedRewards <= tokenLimitPerMonth[month], "Month Limit Reached");
        userDetails.lastRewardCliamed = claimedRewards;
        userDetails.totalRewardsClaimed += claimedRewards;
        tokenCliamedPerMonth[year][month] += claimedRewards;
        token.transfer(_msgSender(), claimedRewards);
        emit TotalRewardsClaimed(claimedRewards, rewards, userDetails.toClaim);
    }

    function getRewardsCalc(
        uint8 _category,
        uint256 _id,
        address _addr
    )
        public
        view
        returns
        (uint256 rewardAmount)
    {
        UserTokenDetails storage user = userTokenDetailsMap[_addr];
        CATEGORY category = CATEGORY(_category);
        uint256 purchaseTime = nftContract.getLastPurchaseTime(_id, _addr);
        uint256 timeDuration = block.timestamp - purchaseTime;
        uint256 dayCount = timeDuration / 1 days;
        if(dayCount != 0) {
            rewardAmount = dayCount <= 365
                ? dayCount * RewardsMap[category][1]
                : (dayCount > 365 && timeDuration <= 730)
                ? (365 * RewardsMap[category][1]) + ((dayCount - 365) * RewardsMap[category][2])
                : dayCount > 730 && dayCount <= 1095
                ? (365 * RewardsMap[category][1]) + (365 * RewardsMap[category][2]) + ((dayCount - 730) * RewardsMap[category][3])
                : (365 * RewardsMap[category][1]) + (365 * RewardsMap[category][2]) + (365 * RewardsMap[category][3]);
        }
        if(user.lastClaim[_id] > purchaseTime) {
            uint256 cliamDays = (user.lastClaim[_id] - purchaseTime) / 1 days;
            uint256 claimedAmount = cliamDays <= 365
                ? cliamDays * RewardsMap[category][1]
                : cliamDays > 365 && cliamDays <= 730
                ? (365 * RewardsMap[category][1]) + (cliamDays * RewardsMap[category][2])
                : cliamDays > 730 && cliamDays <= 1095
                ? (365 * RewardsMap[category][1]) + (365 * RewardsMap[category][2]) + (cliamDays * RewardsMap[category][3])
                : (365 * RewardsMap[category][1]) + (365 * RewardsMap[category][2]) + (365 * RewardsMap[category][3]);
            rewardAmount -= claimedAmount;
        }
    }

    function updateRewardAmount(
        address _addr,
        uint256 rewardAmount
    )
        external
        returns(bool)
    {
        require(address(nftContract) == msg.sender, "Invalid Caller");
        UserTokenDetails storage userDetails = userTokenDetailsMap[_addr];
        userDetails.toClaim = rewardAmount;
        return true;
    }

    function setRewardsMap(
        uint256 _rewards,
        uint256 _year,
        CATEGORY _category
    )
        external
        onlyOwner
    {
        RewardsMap[_category][_year] = _rewards;
    }

    function getMonthAndYear()
        public
        view
        returns(uint256 month, uint256 year)
    {
        month = getMonth(block.timestamp);
        year = getYear(block.timestamp);
    }
}