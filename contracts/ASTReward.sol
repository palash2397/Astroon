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

contract ASTRewards is OwnableUpgradeable, PausableUpgradeable {
    ERC721EnumerableUpgradeable public NftContract;
    IERC20Upgradeable public token;
    IASTNftSale public _astNftsale;
    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }
    struct UserTokenDetails {
        uint256 purchaseTime;
        uint256 lastClaim;
        uint256 rewardsClaimed;
    }

    mapping(uint256 => mapping(CATEGORY => uint256)) public RewardsMap;
    mapping(address => mapping(uint256 => UserTokenDetails)) public userTokenDetailsMap;
    mapping(uint256 => uint256) public WithdrawlMap; // month to figures

    event HoldngRewardsClaimed(uint256 tokenId, uint256 rewards, CATEGORY _category);
    event SoldTokensRewardsClaimed(uint256 rewards);
    event RewardsClaimedToday(uint256 rewards);

    function initialize(address _nftaddress, address _AstTokenAddr) public initializer {
        NftContract = ERC721EnumerableUpgradeable(_nftaddress);
        token = IERC20Upgradeable(_AstTokenAddr);
        _astNftsale = IASTNftSale(_nftaddress);
        RewardsMap[1][CATEGORY.BRONZE] = 1 * 10**18;
        RewardsMap[1][CATEGORY.SILVER] = 2 * 10**18;
        RewardsMap[1][CATEGORY.GOLD] = 3 * 10**18;
        RewardsMap[1][CATEGORY.PLATINUM] = 4 * 10**18;

        RewardsMap[2][CATEGORY.BRONZE] = (1 / 2) * 10**18;
        RewardsMap[2][CATEGORY.SILVER] = ((2 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.GOLD] = ((3 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.PLATINUM] = ((4 * 1) / 2) * 10**18;

        RewardsMap[3][CATEGORY.BRONZE] = ((1 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.SILVER] = ((2 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.GOLD] = ((3 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.PLATINUM] = ((4 * 1) / 4) * 10**18;

        WithdrawlMap[1] = 0 * 10**18;
        WithdrawlMap[2] = 100 * 10**18;
        WithdrawlMap[3] = 200 * 10**18;
        WithdrawlMap[4] = 300 * 10**18;
        WithdrawlMap[5] = 300 * 10**18;
        WithdrawlMap[6] = 750 * 10**18;
        WithdrawlMap[7] = 750 * 10**18;
        WithdrawlMap[8] = 750 * 10**18;
        WithdrawlMap[9] = 750 * 10**18;
        WithdrawlMap[10] = 1500 * 10**18;
        WithdrawlMap[11] = 1500 * 10**18;
        WithdrawlMap[12] = 2500 * 10**18;
        __Ownable_init();
        __Pausable_init();
    }

    function claim() external {
        address _user = msg.sender;
        uint256 rewards;
        uint256 TotalRewards;
        uint256 nftBalance = IERC721EnumerableUpgradeable(NftContract).balanceOf(_user);

        for (uint256 i = 0; i < nftBalance; i++) {
            uint256 id = IERC721EnumerableUpgradeable(NftContract).tokenOfOwnerByIndex(_user, i);
            uint8 x = uint8(_astNftsale.getCategory(id));

            rewards = getRewardsCalc(x, id, _user);
            TotalRewards += rewards;

            UserTokenDetails memory _UserD = userTokenDetailsMap[_user][id];

            _UserD.lastClaim = block.timestamp;
            _UserD.rewardsClaimed += rewards;
            userTokenDetailsMap[_user][id] = _UserD;

            emit HoldngRewardsClaimed(id, rewards, CATEGORY(x));
        }
        uint256 _soldTokenRewards = _astNftsale.userDetailsMap(_user).SoldTokenRewards;
        uint256 userLastDueRewards = _astNftsale.userDetailsMap(_user).dueRewards;
        // get sold token rewards
        uint256 CanClaimRewards = TotalRewards + _soldTokenRewards + userLastDueRewards; // user can claim
        uint256 _allowedWithdrawl = allowedWithdraw(); // allowed this month
        uint256 Actual_claimedRewards = CanClaimRewards > _allowedWithdrawl ? _allowedWithdrawl : CanClaimRewards;
        uint256 dueRewards = CanClaimRewards > _allowedWithdrawl ? CanClaimRewards - _allowedWithdrawl : 0;
        _astNftsale.updateUserDetails(_user, Actual_claimedRewards, dueRewards, 0);

        // user's TotalRewardsClaimed updated , & user's dueRewards updated , soldtokensrewards
        //updated zero, as they had transferred to user
        token.transfer(_msgSender(), Actual_claimedRewards);
        emit SoldTokensRewardsClaimed(_soldTokenRewards);
        emit RewardsClaimedToday(Actual_claimedRewards);
    }

    function set_rewards(
        uint256 _year,
        uint256 _rewardQty,
        CATEGORY _x
    ) external onlyOwner {
        RewardsMap[_year][_x] = _rewardQty;
    }

    function getRewardsCalc(
        uint8 _x,
        uint256 _id,
        address _addr
    ) public view returns (uint256) {
        UserTokenDetails memory _UserD = userTokenDetailsMap[_addr][_id];
        CATEGORY z = CATEGORY(_x);
        uint256 C = _UserD.lastClaim;

        uint256 M1 = _UserD.purchaseTime + 365 days;
        uint256 M2 = _UserD.purchaseTime + 731 days;
        uint256 M3 = _UserD.purchaseTime + 1096 days;

        uint256 RM1 = RewardsMap[1][z];
        uint256 RM2 = RewardsMap[2][z];
        uint256 RM3 = RewardsMap[3][z];

        uint256 currLyingYear = (block.timestamp <= M1) ? 1 : (block.timestamp <= M2) ? 2 : (block.timestamp <= M3)
            ? 3
            : 4;
        uint256 lastClaimYear = (C <= M1) ? 1 : (C <= M2) ? 2 : (C <= M3) ? 3 : 50;

        uint256 total = currLyingYear == 1 ? (block.timestamp - C) * RM1 : currLyingYear == 2 && lastClaimYear == 2
            ? (block.timestamp - C) * RM2
            : currLyingYear == 2 && lastClaimYear == 1
            ? (block.timestamp - M1) * RM2 + (M1 - C) * RM1
            : currLyingYear == 3 && lastClaimYear == 3
            ? (block.timestamp - C) * RM3
            : currLyingYear == 3 && lastClaimYear == 2
            ? (block.timestamp - M2) * RM3 + (M2 - C) * RM2
            : currLyingYear == 3 && lastClaimYear == 1
            ? (block.timestamp - M2) * RM3 + (M2 - M1) * RM2 + (M1 - C) * RM1
            : (M3 - M2) * RM3 + (M2 - M1) * RM2 + (M1 - C) * RM1;

        uint256 calc = total / 86400;
        return calc;
    }

    // to calculate rewards to claim till date
    function rewards_To_claim(address _addr, uint256 tokenId) external view returns (uint256 rewards) {
        uint256 id = IERC721EnumerableUpgradeable(NftContract).tokenOfOwnerByIndex(_addr, tokenId);
        uint8 x = uint8(_astNftsale.getCategoryOf(id));
        rewards = getRewardsCalc(x, id, _addr);

        return rewards;
    }

    function allowedWithdraw() internal view returns (uint256) {
        uint256 currMonth = DateTime.getMonth(block.timestamp);
        return WithdrawlMap[currMonth];
    }

    function setWithdrawalLimits(uint256 _month, uint256 _limit) external onlyOwner {
        WithdrawlMap[_month] = _limit;
    }

    function setRewardsMap(
        uint256 _rewards,
        uint256 _year,
        CATEGORY _x
    ) external onlyOwner {
        RewardsMap[_year][_x] = _rewards * 10**18;
    }

    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    fallback() external payable {}

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}