// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IASTRewards.sol";


contract ASTNftSale is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIdCount;
    IERC20MetadataUpgradeable public token;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension;
    uint256 maxPresaleLimit;
    bool public revealed;
    uint256 minToken;
    uint256 private saleId;
    uint256 private revealedTime;
    bool public rewardEnable;
 
    struct SaleInfo {
        uint256 cost;
        uint256 mintCost;
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
        uint256 remainingSupply;
    }

    struct tierInfo {
        uint256 minValue;
        uint256 maxValue;
    }

    // Events
    event SaleStart(uint256 saleId);
    event BoughtNFT(address indexed to, uint256 amount, uint256 saleId);

    // Mapping 
    mapping(uint256 => CATEGORY) categoryOf; // ID to category
    mapping(CATEGORY => uint256[]) tokensByCategory; // array of token IDs
    mapping(uint256 => SaleInfo) public SaleDetailMap; // sale mapping 
    mapping(uint256 => tierInfo) public tierMap; // tier mapping
    mapping(address => uint256) userSpendInfo;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _tokenAddr,
        string memory _baseExtension,
        uint256 _maxPresaleLimit,
        uint256 _minToken,
        address _receiverAddress,
        uint96 _royaltyAmt
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ERC2981_init();
        __ERC2981_init_unchained();
        baseURI = _baseUri;
        baseExtension = _baseExtension;
        maxPresaleLimit = _maxPresaleLimit;
        minToken = _minToken;
        token = IERC20MetadataUpgradeable(_tokenAddr);
        saleId = 1;
        rewardEnable = true;
        _setDefaultRoyalty(_receiverAddress, _royaltyAmt);
        tierMap[1].minValue=1500*10**18;
        tierMap[1].maxValue=(3000*10**18);

        tierMap[2].minValue=3000*10**18;
        tierMap[2].maxValue=(4500*10**18);   

        tierMap[3].minValue=4500*10**18;
        tierMap[3].maxValue=(6000*10**18);

        tierMap[4].minValue=6000*10**18;
        tierMap[4].maxValue=(7500*10**18);
     }
    IASTRewards public astRewards;

    function setMaxPreSaleLimit(uint256 _presaleLimit) external   {
        maxPresaleLimit = _presaleLimit;
    }
    function setTireMap(
        uint256 _tierLevel,
        uint256 _min,
        uint256 _max
    ) external onlyOwner {
        tierMap[_tierLevel].minValue = _min;
        tierMap[_tierLevel].maxValue = _max;
    }

    function setMintCost(uint256 _id, uint256 _newMintCost) external  {
        SaleDetailMap[_id].mintCost =_newMintCost;
    }
    function getRevealedTime() external view returns(uint256){ 
        return revealedTime;
    }

    // Start Sale
    function startPreSale(
        uint256 _cost,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _startTime,
        uint256 _endTime
    ) external   returns (uint256) {
        SaleDetailMap[saleId] = SaleInfo(
            _cost,
            _mintCost,
            _maxSupply, 
            _startTime,
            _endTime,
            _maxSupply
        );
        emit SaleStart(saleId);
        return saleId;
    }
    function setRevealed() external   {
        revealed = !revealed;
    }

    function setMinimumToken(uint256 _minToken) external   {
        minToken = _minToken;
    }

    function getCategory(uint256 tokenId) external view returns (CATEGORY) {
        return categoryOf[tokenId];
    }
    function getAllTokenByCategory(
        CATEGORY nftType
    ) external view returns (uint256[] memory) {
        return tokensByCategory[nftType];
    }

    function setRewardStatus() external   { 
        rewardEnable = !rewardEnable;
    }

    function updateCategory(
        CATEGORY[] memory _category,
        uint256[] memory _id
    ) external   {
        require(_category.length == _id.length, "Invalid length");
        for (uint256 i; i < _category.length; i++) {
            categoryOf[_id[i]] = _category[i];
            tokensByCategory[_category[i]].push(_id[i]);
        }
    }

    function UpdateTokenAddress(address _tokenAddr) external   {
        token = IERC20MetadataUpgradeable(_tokenAddr);
    }

    function validateNftLimit(address _addr, uint256 nftQty) internal view {
        uint256 tokenBalance = token.balanceOf(_addr);
        uint256 nftBalance = balanceOf(_addr);
        uint256 spendAmount = userSpendInfo[_addr]+tokenBalance;
        require(spendAmount >= minToken, "Insufficient balance");
        require(
            nftBalance + nftQty <= maxPresaleLimit,
            "buying Limit exceeded"
        );

          uint256 count = spendAmount  >= tierMap[1].minValue &&
            spendAmount < tierMap[1].maxValue
            ? 2
            : spendAmount >= tierMap[2].minValue &&
                spendAmount< tierMap[2].maxValue
            ? 4
            : spendAmount >= tierMap[3].minValue &&
                spendAmount < tierMap[3].maxValue
            ? 6
            :spendAmount >= tierMap[4].minValue &&
                spendAmount < tierMap[4].maxValue
            ? 8 
            :10 ;
        require(
            count >= nftBalance && (count - nftBalance) >= nftQty,
            "buying Limit exceeded"
        );
    }

    function setRewardContract(IASTRewards _astRewards) external   {
        astRewards = _astRewards;
    }

    function buyPresale(uint256 nftQty) external payable {
        require(
            SaleDetailMap[saleId].startTime <= block.timestamp &&
                SaleDetailMap[saleId].endTime >= block.timestamp,
            "PrivateSale is InActive"
        );
        require(msg.value == nftQty*(SaleDetailMap[saleId].mintCost), "Insufficient balance");
        validateNftLimit(_msgSender(), nftQty);
        
        require(
            tokenIdCount.current() + nftQty <= SaleDetailMap[saleId].maxSupply,
            "Not enough tokens"
        );
        SaleDetailMap[saleId].remainingSupply -= nftQty; 
        for (uint256 i; i < nftQty; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current(); 
         
            _safeMint(_msgSender(), _id);
            i++;
        }
        userSpendInfo[_msgSender()] += nftQty*(SaleDetailMap[saleId].cost);
        token.transferFrom(msg.sender, address(this), nftQty*(SaleDetailMap[saleId].cost));
        payable(owner()).transfer(msg.value);
        emit BoughtNFT(_msgSender(), nftQty, saleId);
    }

    function minting(
        CATEGORY[] memory _category
    
    ) external   {
        for (uint256 i; i < _category.length; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            categoryOf[_id] = _category[i];
            tokensByCategory[_category[i]].push(_id);
            i++;  
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, "");
    }

    function checkTokenRewardEligibility(uint256 _tokenId) public  view returns (bool IsEligible) {
        if (_tokenId >= 1 && _tokenId <= 2400 && block.timestamp < revealedTime+ 1095 days) {
            IsEligible = true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        if ( 
            (rewardEnable && from != address(0)) && checkTokenRewardEligibility(tokenId)){
            uint256 _rewards = astRewards.getRewardsCalc(
                tokenId
            );
              astRewards.updateData(tokenId, _rewards, from);
        }
       
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(
        uint256 tokenId 
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),  
                        baseExtension
                    )
                )
                : "";
    }

    function reveal() external   {
        revealed = true;
        revealedTime=block.timestamp;

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external    {
       _setDefaultRoyalty( receiver,  feeNumerator);
    }

    function setBaseURI(string memory _newBaseURI) external   {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(
        string memory _notRevealedURI
    ) external   {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) external   {
        baseExtension = _newBaseExtension;
    }

    function setCost(uint256 _saleId, uint256 _newCost) external   {
        SaleDetailMap[_saleId].cost = _newCost;
    }

    function isActive() external view returns (bool) {
        SaleInfo memory detail = SaleDetailMap[saleId];
        return (block.timestamp >= detail.startTime && // Must be after the start date
            block.timestamp <= detail.endTime); // Must be before the end date
    }

    function pause() external   {
        _pause();
    }

    function unpause() external   {
        _unpause();
    }

    function withdrawAmount() external   {
        payable(owner()).transfer(address(this).balance);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  
}
