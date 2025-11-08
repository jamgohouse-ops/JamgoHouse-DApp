// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Jamgo House Listing
/// @notice Registra y administra ofertas de mango para su venta en Avalanche.
/// @dev priceWeiPerKg se expresa en wei/kg; ipfsHash almacena un CID de IPFS.
contract ListingContract {
    // ----------------------
    // Estructuras y estado
    // ----------------------
    struct Listing {
        address producer;
        string variety;        // p.ej., "Mango Manzano"
        uint256 priceWeiPerKg; // precio en wei por kg (enteros, sin decimales)
        uint256 stockKg;       // cantidad disponible en kg
        string ipfsHash;       // ipfs://<CID>
        bool active;           // habilitada para compras
    }

    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;

    // ----------------------
    // Eventos
    // ----------------------
    event ListingCreated(
        uint256 indexed listingId,
        address indexed producer,
        string variety,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        string ipfsHash
    );

    event ListingUpdated(
        uint256 indexed listingId,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        bool active
    );

    event ListingDeactivated(uint256 indexed listingId);

    // ----------------------
    // Modificadores
    // ----------------------
    /// @dev Verifica que la oferta exista y que msg.sender sea su productor.
    /// @param listingId Identificador de la oferta.
    modifier onlyProducer(uint256 listingId) {
        require(listingId < nextListingId, "Oferta inexistente");
        require(listings[listingId].producer == msg.sender, "No es el productor");
        _;
    }

    // ----------------------
    // Funciones principales
    // ----------------------

    /// @notice Crea una nueva oferta de mango.
    /// @param variety Nombre de la variedad (p.ej., "Mango Manzano").
    /// @param priceWeiPerKg Precio por kilogramo en wei (usa enteros).
    /// @param stockKg Cantidad disponible en kilogramos (entero).
    /// @param ipfsHash CID/IPFS con metadatos e imagen (prefijo ipfs:// recomendado).
    /// @return listingId Identificador único de la oferta creada.
    function createListing(
        string memory variety,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        string memory ipfsHash
    ) external returns (uint256 listingId) {
        // ✅ Validaciones
        require(bytes(variety).length > 0, "Variedad requerida");
        require(priceWeiPerKg > 0, "Precio invalido");
        require(stockKg > 0, "Cantidad invalida");
        require(bytes(ipfsHash).length > 0, "CID/IPFS requerido");

        // Crear y guardar
        listingId = nextListingId;
        listings[listingId] = Listing({
            producer: msg.sender,
            variety: variety,
            priceWeiPerKg: priceWeiPerKg,
            stockKg: stockKg,
            ipfsHash: ipfsHash,
            active: true
        });

        emit ListingCreated(listingId, msg.sender, variety, priceWeiPerKg, stockKg, ipfsHash);
        nextListingId = listingId + 1;
    }

    /// @notice Actualiza precio, stock y estado (activa/inactiva) de una oferta.
    /// @dev Solo el productor dueño de la oferta puede actualizarla.
    /// @param listingId Identificador de la oferta.
    /// @param newPriceWeiPerKg Nuevo precio en wei/kg (>0).
    /// @param newStockKg Nuevo stock en kg (>=0).
    /// @param active Nueva bandera de disponibilidad.
    function updateListing(
        uint256 listingId,
        uint256 newPriceWeiPerKg,
        uint256 newStockKg,
        bool active
    ) external onlyProducer(listingId) {
        require(newPriceWeiPerKg > 0, "Precio invalido");
        // Permitimos stock 0 para dejar la oferta visible pero sin disponibilidad
        require(newStockKg >= 0, "Cantidad invalida");

        Listing storage L = listings[listingId];
        L.priceWeiPerKg = newPriceWeiPerKg;
        L.stockKg = newStockKg;
        L.active = active;

        emit ListingUpdated(listingId, newPriceWeiPerKg, newStockKg, active);
        if (!active) {
            emit ListingDeactivated(listingId);
        }
    }

    /// @notice Desactiva definitivamente una oferta (atajo).
    /// @param listingId Identificador de la oferta.
    function deactivate(uint256 listingId) external onlyProducer(listingId) {
        Listing storage L = listings[listingId];
        require(L.active, "Ya inactiva");
        L.active = false;
        emit ListingDeactivated(listingId);
    }

    // ----------------------
    // Funciones de lectura
    // ----------------------

    /// @notice Obtiene los datos completos de una oferta.
    /// @param listingId Identificador de la oferta.
    /// @return producer Dirección del productor.
    /// @return variety Variedad del mango.
    /// @return priceWeiPerKg Precio en wei por kg.
    /// @return stockKg Stock disponible en kg.
    /// @return ipfsHash CID/IPFS con metadatos.
    /// @return active Bandera de disponibilidad.
    function getListing(uint256 listingId)
        external
        view
        returns (
            address producer,
            string memory variety,
            uint256 priceWeiPerKg,
            uint256 stockKg,
            string memory ipfsHash,
            bool active
        )
    {
        require(listingId < nextListingId, "Oferta inexistente");
        Listing storage L = listings[listingId];
        return (L.producer, L.variety, L.priceWeiPerKg, L.stockKg, L.ipfsHash, L.active);
    }
}

