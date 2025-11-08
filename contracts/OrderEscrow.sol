// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/Strings.sol";

interface ITraceMangoNFT {
    function mintFromEscrow(address to, string calldata tokenURI) external returns (uint256);
}

contract OrderEscrow {
    using Strings for uint256;

    struct Order {
        address buyer;
        address producer;
        uint256 listingId;
        uint256 kg;
        uint256 amountWei;
        bool paid;
        bool released;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;

    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    ITraceMangoNFT public traceNFT;
    string public baseURI;

    event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 amountWei);
    event FundsReleased(uint256 indexed orderId, address indexed producer, uint256 amountWei);
    event Refunded(uint256 indexed orderId, address indexed buyer, uint256 amountWei);
    event NFTMinted(uint256 indexed orderId, address indexed to, uint256 tokenId, string tokenURI);

    // ✅ SOLO baseURI en el constructor
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    function setNFTContract(address _nft) external onlyOwner {
        traceNFT = ITraceMangoNFT(_nft);
    }

    function payOrder(address producer, uint256 listingId, uint256 kg) external payable {
        require(producer != address(0), "Productor invalido");
        require(kg > 0, "Cantidad invalida");
        require(msg.value > 0, "Monto invalido");

        orders[nextOrderId] = Order({
            buyer: msg.sender,
            producer: producer,
            listingId: listingId,
            kg: kg,
            amountWei: msg.value,
            paid: true,
            released: false
        });

        emit OrderPaid(nextOrderId, msg.sender, msg.value);
        nextOrderId++;
    }

    function release(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.paid, "Pago no realizado");
        require(!order.released, "Fondos ya liberados");
        require(order.buyer == msg.sender, "Solo el comprador puede liberar");

        order.released = true;
        payable(order.producer).transfer(order.amountWei);
        emit FundsReleased(orderId, order.producer, order.amountWei);

        if (address(traceNFT) != address(0)) {
            string memory tokenURI = string(abi.encodePacked(baseURI, orderId.toString(), ".json"));
            uint256 tokenId = traceNFT.mintFromEscrow(order.buyer, tokenURI);
            emit NFTMinted(orderId, order.buyer, tokenId, tokenURI);
        }
    }

    function refund(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.paid, "Pedido no pagado");
        require(!order.released, "Ya liberado");
        require(order.producer == msg.sender, "Solo productor puede reembolsar");

        uint256 amount = order.amountWei;
        order.amountWei = 0;
        order.released = true;
        payable(order.buyer).transfer(amount);

        emit Refunded(orderId, order.buyer, amount);
    }
}

