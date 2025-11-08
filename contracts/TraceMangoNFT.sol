// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TraceMangoNFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    address public minter; // contrato escrow autorizado

    constructor(address _minter)
        ERC721("TraceMango", "TMGO")
        Ownable(msg.sender) // ✅ aquí pasamos el owner al constructor de Ownable
    {
        minter = _minter;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// @notice Mint llamado exclusivamente por el escrow cuando se libera un pedido.
    function mintFromEscrow(address to, string memory tokenURI) external returns (uint256) {
        require(msg.sender == minter, "Only escrow can mint");
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }
}
