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
import "@openzeppelin/contracts/utils/Strings.sol";

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
    bool public revealed;
    uint256 maxPresaleLimit;
    uint256 minToken;
    uint256 private saleId;

    struct PresaleInfo {
        uint256 cost;
        uint256 mintCost;
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
        uint256 remainingSupply;
    }

    // Events
    event SaleStart(uint256 saleId);
    event BoughtNFT(address indexed to, uint256 amount, uint256 saleId);

    // Mapping
    mapping(uint256 => CATEGORY) categoryOf; // ID to category
    mapping(CATEGORY => uint256[])  tokensByCategory; // array of token IDs

    mapping(uint256 => PresaleInfo) public SaleInfoMap; // sale mapping
    mapping(uint256 => mapping(address => uint256)) public lastPurchasedAt;
  

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _tokenAddr,
        string memory _baseExtension,
        uint256 _maxPresaleLimit,
        uint256 _minToken
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
        saleId=1;
    }

    function setMaxPreSaleLimit(uint256 _presaleLimit) external onlyOwner {
        maxPresaleLimit = _presaleLimit;
    }

    // Start Sale
    function startPreSale(
        uint256 _cost,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _startTime,
        uint256 _endTime       
    ) external onlyOwner returns (uint256) {
        SaleInfoMap[saleId] = PresaleInfo(
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

    function setMinimumToken(uint256 _minToken) external onlyOwner {
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

     function updateCategory(CATEGORY[] memory _category, uint256 _id) external  onlyOwner{
        for (uint256 i; i <_category.length; i++) {
        categoryOf[_id] = _category[i];
        tokensByCategory[_category[i]].push(_id);
        _id++;
        }
    }
    function UpdateTokenAddress(address _tokenAddr) external onlyOwner {
        token = IERC20MetadataUpgradeable(_tokenAddr);
    }

    function validateNftLimit(address _addr, uint256 nftQty) internal view {
        uint256 tokenBalance = token.balanceOf(_addr);
        uint256 nftBalance = balanceOf(_addr);
        require(tokenBalance >= minToken, "Insufficient balance");
        require(
            nftBalance + nftQty <= maxPresaleLimit,
            "buying Limit exceeded"
        );
        uint256 count = tokenBalance >= 100* 10**18 &&
            tokenBalance <= 300* 10**18
            ? 1
            : tokenBalance >= 301* 10**18 &&
                tokenBalance <= 600* 10**18
            ? 2
            : tokenBalance >= 601* 10**18 &&
                tokenBalance <= 800* 10**18
            ? 3
            : 4;

        require(
            count >= nftBalance && (count - nftBalance) >= nftQty,
            "buying Limit exceeded"
        );
    }

    function getLastPurchaseTime(
        uint256 tokenId,
        address userAddress
    ) external view returns (uint256) {
        return lastPurchasedAt[tokenId][userAddress];
    }

    function buyPresale(uint256 nftQty) external payable {
        require(
            SaleInfoMap[saleId].startTime <= block.timestamp &&
                SaleInfoMap[saleId].endTime >= block.timestamp,
            "PrivateSale is InActive"
        );

        validateNftLimit(_msgSender(), nftQty);
        require(
            msg.value ==
                (nftQty *
                    (SaleInfoMap[saleId].cost +
                        SaleInfoMap[saleId].mintCost)),
            "Insufficient value"
        );
        require(
            tokenIdCount.current() + nftQty <=
                SaleInfoMap[saleId].maxSupply,
            "Not enough tokens"
        );
        SaleInfoMap[saleId].remainingSupply-=nftQty;
        for (uint256 i; i < nftQty; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            i++;
        }
        payable(owner()).transfer(msg.value);
        emit BoughtNFT(_msgSender(), nftQty, saleId);
    }

    function minting(
        CATEGORY[] memory _category,
        string[] memory _tokenURI
      
    ) external onlyOwner payable {
    
     
        for (uint256 i; i < _category.length; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            categoryOf[_id] = _category[i];
            tokensByCategory[_category[i]].push(_id);
            _setTokenURI(_id, _tokenURI[i]);
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
        lastPurchasedAt[tokenId][to] = block.timestamp;
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

    function reveal() external onlyOwner {
        revealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(
        string memory _notRevealedURI
    ) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setCost(uint256 _saleId, uint256 _newCost) external onlyOwner {
        SaleInfoMap[_saleId].cost = _newCost;
    }

    function setMintCost(
        uint256 _saleId,
        uint256 _newMintCost
    ) external onlyOwner {
        SaleInfoMap[_saleId].mintCost = _newMintCost;
    }

    function isActive() external view returns (bool) {
        PresaleInfo memory detail = SaleInfoMap[saleId];
        return (block.timestamp >= detail.startTime && // Must be after the start date
            block.timestamp <= detail.endTime); // Must be before the end date
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAmount() external onlyOwner {
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
