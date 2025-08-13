import {
  bitcoin_network,
  bitcoin_get_balance_args,
  satoshi,
  bitcoin_get_balance_result,
} from "azle/canisters/management/idl";
import { call, Principal } from "azle";
import express, { Request } from "express";

// Dummy values instead of real Bitcoin interactions
const NETWORK: bitcoin_network = { testnet: null };
const DERIVATION_PATH: Uint8Array[] = [];
const KEY_NAME: string = "test_key_1";

const app = express();
app.use(express.json());

/// Returns a welcome message to test if the API is working.
app.get("/", async (req: Request, res) => {
  const welcomeMessage = {
    message: "Welcome to the Bitcoin Canister API",
  };
  res.json(welcomeMessage);
});

/// Returns the actual balance of a given Bitcoin address using ICP Chain Fusion.
/// NOTE: service only available on Mainnet (dfx deploy --ic).
app.post("/get-balance", async (req: Request, res) => {
  try {
    const { address } = req.body;

    if (!address) {
      return res.status(400).json({
        error: "Address is required",
      });
    }

    // Prepare arguments for the management canister call
    const args: bitcoin_get_balance_args = {
      address: address,
      network: NETWORK,
      min_confirmations: [], // Optional: use default confirmations
    };

    // Call the management canister to get the actual Bitcoin balance
    const balanceInSatoshi: satoshi = await call(
      Principal.fromText("aaaaa-aa"),
      "bitcoin_get_balance",
      {
        args: [args],
        paramIdlTypes: [bitcoin_get_balance_args],
        returnIdlType: satoshi,
      },
    );

    // Convert satoshi to BTC (1 BTC = 100,000,000 satoshi)
    const balanceInBTC = Number(balanceInSatoshi) / 100_000_000;

    const response = {
      address: address,
      balance: balanceInBTC,
      balanceInSatoshi: Number(balanceInSatoshi),
      unit: "BTC",
      network: NETWORK,
    };

    res.json(response);
  } catch (error: any) {
    console.error("Error getting Bitcoin balance:", error);
    res.status(500).json({
      error: "Failed to get Bitcoin balance",
      message: error.message || "Unknown error occurred",
    });
  }
});

/// Dummy: Returns the UTXOs of a given Bitcoin address.
app.post("/get-utxos", async (req: Request, res) => {
  const { address } = req.body;
  const dummyUtxos = [
    {
      txid: "dummy-txid-1",
      vout: 0,
      value: 25000,
      confirmations: 5,
    },
    {
      txid: "dummy-txid-2",
      vout: 1,
      value: 50000,
      confirmations: 3,
    },
  ];
  res.json(dummyUtxos);
});

/// Dummy: Returns the 100 fee percentiles measured in millisatoshi/byte.
app.post("/get-current-fee-percentiles", async (_req, res) => {
  const dummyFees = Array.from({ length: 100 }, (_, i) => 100 + i); // Example: [100, 101, ..., 199]
  res.json(dummyFees);
});

/// Dummy: Returns the P2PKH address of this canister.
app.post("/get-p2pkh-address", async (_req, res) => {
  const dummyAddress = "tb1qdummyaddressxyz1234567890";
  res.json({ address: dummyAddress });
});

/// Dummy: Sends satoshis from this canister to a specified address.
app.post("/send", async (req, res) => {
  try {
    const { destinationAddress, amountInSatoshi } = req.body;

    const dummyTxId = "dummy-txid-sent-1234567890";
    const response = {
      success: true,
      destination: destinationAddress,
      amount: amountInSatoshi,
      txId: dummyTxId,
    };
    res.json(response);
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: {
        code: "DUMMY_ERROR",
        message: "This is a dummy error response",
        details: null,
      },
    });
  }
});

/// Dummy test endpoint
app.post("/dummy-test", (_req, res) => {
  const dummyResponse = {
    status: "success",
    data: {
      message: "This is a dummy response",
      timestamp: new Date().toISOString(),
      testData: {
        id: 1,
        name: "Test Bitcoin Data",
        value: 0.001,
        isTest: true,
      },
    },
  };
  res.json(dummyResponse);
});

app.use(express.static("/dist"));

app.listen();

export function determineKeyName(network: bitcoin_network): string {
  return "test_key_1"; // always return dummy key
}

export function determineNetwork(
  networkName?: string,
): bitcoin_network | undefined {
  return { testnet: null }; // always return dummy network
}
