// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ListingContract {
    struct Listing {
        address producer;
        string variety;        // p.ej., "Mango Manzano"
        uint256 priceWeiPerKg; // precio en wei por kg (AVAX)
        uint256 stockKg;       // stock en kg
        string ipfsHash;       // metadatos/foto (ipfs://CID)
        bool active;
    }

    uint256 public nextId;
    mapping(uint256 => Listing) public listings;

    event ListingUpdated(
        uint256 indexed id,
        address indexed producer,
        string variety,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        string ipfsHash,
        bool active
    );

    modifier onlyProducer(uint256 id) {
        require(listings[id].producer == msg.sender, "Not producer");
        _;
    }

    function createListing(
        string calldata variety,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        string calldata ipfsHash
    ) external returns (uint256 id) {
        require(priceWeiPerKg > 0 && stockKg > 0, "Invalid vals");
        id = ++nextId;
        listings[id] = Listing({
            producer: msg.sender,
            variety: variety,
            priceWeiPerKg: priceWeiPerKg,
            stockKg: stockKg,
            ipfsHash: ipfsHash,
            active: true
        });
        emit ListingUpdated(id, msg.sender, variety, priceWeiPerKg, stockKg, ipfsHash, true);
    }

    function updateListing(
        uint256 id,
        uint256 newPriceWeiPerKg,
        uint256 newStockKg,
        bool active
    ) external onlyProducer(id) {
        require(newPriceWeiPerKg > 0, "Price=0");
        listings[id].priceWeiPerKg = newPriceWeiPerKg;
        listings[id].stockKg = newStockKg;
        listings[id].active = active;
        emit ListingUpdated(
            id,
            msg.sender,
            listings[id].variety,
            newPriceWeiPerKg,
            newStockKg,
            listings[id].ipfsHash,
            active
        );
    }

    function getListing(uint256 id) external view returns (Listing memory) {
        return listings[id];
    }
}
