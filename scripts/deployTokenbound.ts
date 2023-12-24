import hre from "hardhat";
import fs from "fs";
import path from "path";
import { getContract, createPublicClient, http } from "viem";

import { victionTestnet } from "../chains/VictionTestnet";

import {
  abi as registryAbi,
  bytecode as registryBytecode,
} from "../artifacts/contracts/tokenbound/ERC6551Registry.sol/ERC6551Registry.json";
import {
  abi as tokenboundAbi,
  bytecode as tokenboundBytecode,
} from "../artifacts/contracts/tokenbound/ERC6551Account.sol/ERC6551Account.json";

function sleep(time: any) {
  return new Promise((resolve) => setTimeout(resolve, time));
}

async function main() {
  // Set before deployment
  const NETWORK = "viction";

  const publicClient = createPublicClient({
    chain: victionTestnet,
    transport: http(),
  });
  const [walletClient] = await hre.viem.getWalletClients({ chain: victionTestnet });

  console.log("Deploying...");

  console.log("Deploying ERC-6551 registry contract...");
  // @ts-ignore
  const registryHash = await walletClient.deployContract({
    abi: registryAbi,
    account: walletClient.account.address,
    bytecode: registryBytecode,
  });
  // @ts-ignore
  const { contractAddress: registry } = await publicClient.waitForTransactionReceipt({
    hash: registryHash,
  });
  // @ts-ignore
  const registryCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Registry contract: ${registry}, with nonce: ${registryCount}`);

  console.log("Deploying ERC-6551 tokenbound account contract...");
  // @ts-ignore
  const tokenboundHash = await walletClient.deployContract({
    abi: tokenboundAbi,
    account: walletClient.account.address,
    bytecode: tokenboundBytecode,
  });
  // @ts-ignore
  const { contractAddress: tokenbound } = await publicClient.waitForTransactionReceipt({
    hash: tokenboundHash,
  });
  // @ts-ignore
  const athorizationCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Tokenbound account contract: ${tokenbound}, with nonce: ${athorizationCount}`);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    registry,
    tokenbound,
  };

  console.log(addresses);

  // Save the addresses to a file
  const folderPath = "address/tokenbound";

  if (!fs.existsSync(folderPath)) fs.mkdirSync(folderPath);

  const filePath = path.join(folderPath, `address-${NETWORK}.json`);

  fs.writeFile(filePath, JSON.stringify(addresses, undefined, 4), (err) => {
    if (err) console.log("Write file error: " + err.message);
    else console.log(`Addresses are saved into ${filePath}...`);
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
