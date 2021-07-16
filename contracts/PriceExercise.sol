pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// import "./PriceConsumerV3.sol";
// import "./APIConsumer.sol";

contract PriceExercise is ChainlinkClient {
    bool public priceFeedGreater;
    int256 public storedPrice;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    AggregatorV3Interface internal priceFeed;

    /* It’s constructor function should contain a combination of the existing 
PriceConsumerV3 and the APIConsumer contract contract logic, including taking 
in the _priceFeed address parameter like the PriceConsumerV3 contract does, 
as well as all the parameters in the existing APIConsumer contract 
(hint: append the price consumer parameter to the end of the 4 API consumer ones)
*/
    constructor(
        address _oracle,
        string memory _jobId,
        uint256 _fee,
        address _link,
        address _priceFeed
    ) public {}

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function requestPriceData() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        //The ‘requestPriceData’ function should request the BTC price
        // from the URL https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD,
        //set the ‘path’ to the current price returned in the JSON, and
        //multiplying the result by 10**18 before sending the request to a Chainlink oracle
        request.add(
            "get",
            "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD"
        );
        request.add("path", "RAW.BTC.USD.PRICE");

        int256 timesAmount = 10**18;
        request.addInt("times", timesAmount);

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, int256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        storedPrice = _price;
        latestBtcPrice = getLatestPrice();

        (latestBtcPrice > storedPrice)
            ? priceFeedGreater = true
            : priceFeedGreater = false;
    }
}
