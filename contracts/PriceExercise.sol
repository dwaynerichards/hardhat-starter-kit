pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceExercise is ChainlinkClient {
    bool public priceFeedGreater;
    int256 public storedPrice;
    int256 public latestBtcPrice;

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
    ) public {
        //not sure why this is needed
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }

        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

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
        //request the BTC price from https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD,
        request.add(
            "get",
            "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD"
        );
        //set the ‘path’ to the current price returned in the JSON, and
        request.add("path", "RAW.BTC.USD.PRICE");

        //multiplying the result by 10**18
        int256 timesAmount = 10**18;
        request.addInt("times", timesAmount);

        // sending the request to a Chainlink oracle
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, int256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        storedPrice = _price;
        //The price feed current price can be accessed by calling
        // the getLatestPrice() function in your contrac
        latestBtcPrice = getLatestPrice();

        (latestBtcPrice > storedPrice)
            ? priceFeedGreater = true
            : priceFeedGreater = false;
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * Withdraw LINK from this contract
     *
     removed "external"
     */
    function withdrawLink() external {
        LinkTokenInterface linkToken = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        require(
            linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
