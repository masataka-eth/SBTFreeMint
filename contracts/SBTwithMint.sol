// SPDX-License-Identifier: MIT

/*
 * Created by masataka.eth (@masataka_net)
 */

pragma solidity >=0.7.0 <0.9.0;

//import { Base64 } from './libs/base64.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/ITokenURI.sol";
import "./interface/IWalletFamily.sol";

contract SBTwithMint is AccessControl,ERC721AQueryable,ReentrancyGuard  {
    // Upgradable FullOnChain
    ITokenURI public tokenuri;
    IWalletFamily public walletfamily;

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE  = keccak256("BURNER_ROLE");

    string public baseURI;
    string public baseExtension = ".json";
    bool public useSingleMetadata = true;
    string public singleMetadataURI;
    uint256 public maxSupply = 10000;

    constructor(
    // ) ERC721A("CollectionName", "Symbol") {
    ) ERC721A("CNPP Legendary Members", "CNPPLM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE       , msg.sender);
        _grantRole(BURNER_ROLE       , msg.sender);
    }

    // onlyAdmin
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdmin {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyAdmin {
        baseExtension = _newBaseExtension;
    }

    function setUseSingleMetadata(bool _useSingleMetadata) external onlyAdmin {
        useSingleMetadata = _useSingleMetadata;
    }

    function setSingleMetadataURI(string memory _uri) external onlyAdmin{
        singleMetadataURI = _uri;
    }

    function setTokenURI(ITokenURI _tokenuri) external onlyAdmin{
        tokenuri = _tokenuri;
    }



    // internal
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual 
      override(AccessControl,IERC721A,ERC721A) returns (bool) {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // external
    function externalMint(address _address , uint256 _amount ) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _totalMinted() + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }

    function externalBurn(uint256[] memory _burnTokenIds) external nonReentrant{
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(tx.origin == ownerOf(tokenId) , "Owner is different");
            _burn(tokenId);
        }        
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A,ERC721A)  returns (string memory){
        require(_exists(tokenId),"ERC721AMetadata: URI query for nonexistent token");
        if(address(tokenuri) == address(0)){
            if(useSingleMetadata == true){
                return singleMetadataURI;
            }else{
                return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
            }
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    //SBT
    function approve(address , uint256 ) public payable override(IERC721A,ERC721A) {
        require(false, "This token is SBT, so this can not approval.");
    }

    function setApprovalForAll(address , bool ) public pure override(IERC721A,ERC721A) {
        require(false, "This token is SBT, so this can not approval.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A,ERC721A) {
        if(address(walletfamily) != address(0)){
            // migration SBT
            if(walletfamily.isChild(to) == true){
            super.transferFrom(from, to, tokenId);
            return;
            }     
        }
        require(false, "This token is SBT, so this can not transfer.");
    }
}

