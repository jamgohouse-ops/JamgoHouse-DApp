// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IListing {
    function listings(uint256) external view returns (
        address producer,
        string memory variety,
        uint256 priceWeiPerKg,
        uint256 stockKg,
        string memory ipfsHash,
        bool active
    );
}

contract OrderEscrow {
    struct Order {
        address buyer;
        address producer;
        uint256 listingId;
        uint256 kg;
        uint256 amountWei;
        bool paid;
        bool released;
    }

    IListing public listing;
    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;

    event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 listingId, uint256 kg, uint256 amountWei);
    event FundsReleased(uint256 indexed orderId, address indexed producer, uint256 amountWei);
    event Refunded(uint256 indexed orderId, address indexed buyer, uint256 amountWei);

    constructor(address listingAddress) {
        listing = IListing(listingAddress);
    }

    function payOrder(uint256 listingId, uint256 kg) external payable returns (uint256 orderId) {
        (address producer,, uint256 priceWeiPerKg, uint256 stockKg,, bool active) = listing.listings(listingId);
        require(active, "Listing inactive");
        require(kg > 0 && kg <= stockKg, "Invalid kg");

        uint256 total = priceWeiPerKg * kg;
        require(msg.value == total, "Wrong amount");

        orderId = ++nextOrderId;
        orders[orderId] = Order({
            buyer: msg.sender,
            producer: producer,
            listingId: listingId,
            kg: kg,
            amountWei: total,
            paid: true,
            released: false
        });

        emit OrderPaid(orderId, msg.sender, listingId, kg, total);
    }

    // Buyer confirma entrega -> libera fondos al productor
    function release(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.paid && !o.released, "Invalid state");
        require(msg.sender == o.buyer, "Only buyer confirms");
        o.released = true;
        (bool ok, ) = o.producer.call{value: o.amountWei}("");
        require(ok, "Transfer failed");
        emit FundsReleased(orderId, o.producer, o.amountWei);
    }

    // Productor decide reembolsar
    function refund(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.paid && !o.released, "Invalid state");
        require(msg.sender == o.producer, "Only producer can refund");
        o.released = true;
        (bool ok, ) = o.buyer.call{value: o.amountWei}("");
        require(ok, "Refund failed");
        emit Refunded(orderId, o.buyer, o.amountWei);
    }
}
