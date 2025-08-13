import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Time "mo:base/Time";

persistent actor {
  // ----- Type definitions -----
  type HeaderField = (Text, Text);

  type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
    certificate_version : ?Nat16;
  };

  type HttpResponse = {
    status_code : Nat16;
    headers : [HeaderField];
    body : Blob;
    streaming_strategy : ?Null;
    upgrade : ?Bool;
  };

  // API response types
  type WelcomeResponse = {
    message : Text;
  };

  type BalanceResponse = {
    address : Text;
    balance : Float;
    unit : Text;
  };

  type UtxoResponse = {
    txid : Text;
    vout : Nat;
    value : Nat;
    confirmations : Nat;
  };

  type AddressResponse = {
    address : Text;
  };

  type SendResponse = {
    success : Bool;
    destination : Text;
    amount : Nat;
    txId : Text;
  };

  type TestDataResponse = {
    id : Nat;
    name : Text;
    value : Float;
    isTest : Bool;
  };

  type DummyTestResponse = {
    status : Text;
    data : {
      message : Text;
      timestamp : Text;
      testData : TestDataResponse;
    };
  };

  // ----- Public API functions (can be called directly or via HTTP) -----

  // Welcome message
  public shared query func welcome() : async WelcomeResponse {
    {
      message = "Welcome to the Dummy Bitcoin Canister API";
    };
  };

  // Dummy: Returns the balance of a given Bitcoin address
  public shared query func get_balance(address : Text) : async BalanceResponse {
    {
      address = address;
      balance = 0.005;
      unit = "BTC";
    };
  };

  // Dummy: Returns the UTXOs of a given Bitcoin address
  public shared query func get_utxos(_address : Text) : async [UtxoResponse] {
    [
      {
        txid = "dummy-txid-1";
        vout = 0;
        value = 25000;
        confirmations = 5;
      },
      {
        txid = "dummy-txid-2";
        vout = 1;
        value = 50000;
        confirmations = 3;
      },
    ];
  };

  // Dummy: Returns the 100 fee percentiles measured in millisatoshi/byte
  public shared query func get_current_fee_percentiles() : async [Nat] {
    Array.tabulate<Nat>(100, func(i) = 100 + i);
  };

  // Dummy: Returns the P2PKH address of this canister
  public shared query func get_p2pkh_address() : async AddressResponse {
    {
      address = "tb1qdummyaddressxyz1234567890";
    };
  };

  // Dummy: Sends satoshis from this canister to a specified address
  public shared func send(destinationAddress : Text, amountInSatoshi : Nat) : async SendResponse {
    {
      success = true;
      destination = destinationAddress;
      amount = amountInSatoshi;
      txId = "dummy-txid-sent-1234567890";
    };
  };

  // Dummy test endpoint
  public shared query func dummy_test() : async DummyTestResponse {
    let now = Time.now();
    let timestamp = "2024-" # Int.toText(now / 1000000000) # "T00:00:00.000Z";

    {
      status = "success";
      data = {
        message = "This is a dummy response";
        timestamp = timestamp;
        testData = {
          id = 1;
          name = "Test Bitcoin Data";
          value = 0.001;
          isTest = true;
        };
      };
    };
  };

  // ----- Private helper functions -----

  // Extracts send parameters from HTTP request body (simplified demo)
  private func extractSendParams(_body : Blob) : (Text, Nat) {
    ("extracted-destination", 50000);
  };

  // Extracts address from HTTP request body (simplified demo)
  private func extractAddress(_body : Blob) : Text {
    "extracted-address";
  };

  // Constructs a JSON HTTP response
  private func makeJsonResponse(statusCode : Nat16, jsonContent : Text) : HttpResponse {
    {
      status_code = statusCode;
      headers = [("content-type", "application/json"), ("access-control-allow-origin", "*")];
      body = Text.encodeUtf8(jsonContent);
      streaming_strategy = null;
      upgrade = ?true;
    };
  };

  // Handles simple HTTP routes (GET/OPTIONS and fallback)
  private func handleRoute(method : Text, url : Text, _body : Blob) : HttpResponse {
    let normalizedUrl = Text.trimEnd(url, #text "/");

    switch (method, normalizedUrl) {
      case ("GET", "" or "/") {
        makeJsonResponse(200, "{\"message\": \"Welcome to the Dummy Bitcoin Canister API\"}");
      };
      case ("OPTIONS", _) {
        {
          status_code = 200;
          headers = [("access-control-allow-origin", "*"), ("access-control-allow-methods", "GET, POST, OPTIONS"), ("access-control-allow-headers", "Content-Type")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = null;
        };
      };
      case ("POST", "/get-balance" or "/get-utxos" or "/get-current-fee-percentiles" or "/get-p2pkh-address" or "/send" or "/dummy-test") {
        {
          status_code = 200;
          headers = [("content-type", "application/json")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {
        {
          status_code = 404;
          headers = [("content-type", "application/json")];
          body = Text.encodeUtf8("Not found: " # url);
          streaming_strategy = null;
          upgrade = null;
        };
      };
    };
  };

  // Handles POST routes that require async update (e.g., calling other functions)
  private func handleRouteUpdate(method : Text, url : Text, body : Blob) : async HttpResponse {
    let normalizedUrl = Text.trimEnd(url, #text "/");

    switch (method, normalizedUrl) {
      case ("POST", "/get-balance") {
        let address = extractAddress(body);
        let response = await get_balance(address);
        makeJsonResponse(200, "{\"address\": \"" # response.address # "\", \"balance\": " # Float.toText(response.balance) # ", \"unit\": \"" # response.unit # "\"}");
      };
      case ("POST", "/get-utxos") {
        let address = extractAddress(body);
        let utxos = await get_utxos(address);
        let utxoJsonArray = Array.map<UtxoResponse, Text>(
          utxos,
          func(utxo) = "{\"txid\": \"" # utxo.txid # "\", \"vout\": " # Nat.toText(utxo.vout) # ", \"value\": " # Nat.toText(utxo.value) # ", \"confirmations\": " # Nat.toText(utxo.confirmations) # "}",
        );
        let jsonUtxos = "[" # Text.join(", ", utxoJsonArray.vals()) # "]";
        makeJsonResponse(200, jsonUtxos);
      };
      case ("POST", "/get-current-fee-percentiles") {
        let percentiles = await get_current_fee_percentiles();
        let percentileStrings = Array.map<Nat, Text>(percentiles, func(p) = Nat.toText(p));
        let jsonPercentiles = "[" # Text.join(", ", percentileStrings.vals()) # "]";
        makeJsonResponse(200, jsonPercentiles);
      };
      case ("POST", "/get-p2pkh-address") {
        let response = await get_p2pkh_address();
        makeJsonResponse(200, "{\"address\": \"" # response.address # "\"}");
      };
      case ("POST", "/send") {
        let (destination, amount) = extractSendParams(body);
        let response = await send(destination, amount);
        makeJsonResponse(200, "{\"success\": " # "true" # ", \"destination\": \"" # response.destination # "\", \"amount\": " # Nat.toText(response.amount) # ", \"txId\": \"" # response.txId # "\"}");
      };
      case ("POST", "/dummy-test") {
        let response = await dummy_test();
        makeJsonResponse(200, "{\"status\": \"" # response.status # "\", \"data\": {\"message\": \"" # response.data.message # "\", \"timestamp\": \"" # response.data.timestamp # "\", \"testData\": {\"id\": " # Nat.toText(response.data.testData.id) # ", \"name\": \"" # response.data.testData.name # "\", \"value\": " # Float.toText(response.data.testData.value) # ", \"isTest\": " # "true" # "}}}");
      };
      case ("OPTIONS", _) {
        {
          status_code = 200;
          headers = [("access-control-allow-origin", "*"), ("access-control-allow-methods", "GET, POST, OPTIONS"), ("access-control-allow-headers", "Content-Type")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = null;
        };
      };
      case _ {
        return handleRoute(method, url, body);
      };
    };
  };

  // HTTP query interface for GET/OPTIONS and static responses
  public query func http_request(req : HttpRequest) : async HttpResponse {
    return handleRoute(req.method, req.url, req.body);
  };

  // HTTP update interface for POST routes requiring async calls
  public func http_request_update(req : HttpRequest) : async HttpResponse {
    return await handleRouteUpdate(req.method, req.url, req.body);
  };
};