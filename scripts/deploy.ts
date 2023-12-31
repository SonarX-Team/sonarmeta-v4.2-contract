import hre from "hardhat";
import fs from "fs";
import path from "path";
import { getContract, createPublicClient, http } from "viem";

import { victionTestnet } from "../chains/VictionTestnet";

import { abi as creationAbi, bytecode as creationBytecode } from "../artifacts/contracts/Creation.sol/Creation.json";
import {
  abi as authorizationAbi,
  bytecode as authorizationBytecode,
} from "../artifacts/contracts/Authorization.sol/Authorization.json";
import {
  abi as lockingVaultAbi,
  bytecode as lockingVaultBytecode,
} from "../artifacts/contracts/LockingVault.sol/LockingVault.json";
import {
  abi as governanceAbi,
  bytecode as governanceBytecode,
} from "../artifacts/contracts/utils/Governance.sol/Governance.json";
import {
  abi as sonarmetaAbi,
  bytecode as sonarmetaBytecode,
} from "../artifacts/contracts/SonarMeta.sol/SonarMeta.json";
import { abi as businessAbi, bytecode as businessBytecode } from "../artifacts/contracts/Business.sol/Business.json";
import {
  abi as marketplaceAbi,
  bytecode as marketplaceBytecode,
} from "../artifacts/contracts/Marketplace.sol/Marketplace.json";

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

  console.log("Deploying Creation contract...");
  // @ts-ignore
  const creationHash = await walletClient.deployContract({
    abi: creationAbi,
    account: walletClient.account.address,
    bytecode: creationBytecode,
    args: [walletClient.account.address],
  });
  // @ts-ignore
  const { contractAddress: creation } = await publicClient.waitForTransactionReceipt({
    hash: creationHash,
  });
  // @ts-ignore
  const creationCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Creation contract: ${creation}, with nonce: ${creationCount}`);

  console.log("Deploying Authorization contract...");
  // @ts-ignore
  const authorizationHash = await walletClient.deployContract({
    abi: authorizationAbi,
    account: walletClient.account.address,
    bytecode: authorizationBytecode,
    args: ["SonarMeta IP Network Edge", "SMINE", creation, walletClient.account.address],
  });
  // @ts-ignore
  const { contractAddress: authorization } = await publicClient.waitForTransactionReceipt({
    hash: authorizationHash,
  });
  // @ts-ignore
  const athorizationCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Authorization contract: ${authorization}, with nonce: ${athorizationCount}`);

  console.log("Deploying LockingVault contract...");
  // @ts-ignore
  const lockingVaultHash = await walletClient.deployContract({
    abi: lockingVaultAbi,
    account: walletClient.account.address,
    bytecode: lockingVaultBytecode,
    args: [walletClient.account.address, authorization],
  });
  // @ts-ignore
  const { contractAddress: lockingVault } = await publicClient.waitForTransactionReceipt({
    hash: lockingVaultHash,
  });

  // @ts-ignore
  const lockingVaultCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`LockingVault contract: ${lockingVault}, with nonce: ${lockingVaultCount}`);

  console.log("Deploying Governance contract...");
  // @ts-ignore
  const governanceHash = await walletClient.deployContract({
    abi: governanceAbi,
    account: walletClient.account.address,
    bytecode: governanceBytecode,
  });
  // @ts-ignore
  const { contractAddress: governance } = await publicClient.waitForTransactionReceipt({
    hash: governanceHash,
  });
  // @ts-ignore
  const governanceCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Governance contract: ${governance}, with nonce: ${governanceCount}`);

  console.log("Deploying SonarMeta main contract...");
  // @ts-ignore
  const mainHash = await walletClient.deployContract({
    abi: sonarmetaAbi,
    account: walletClient.account.address,
    bytecode: sonarmetaBytecode,
    args: [creation, authorization, lockingVault],
  });
  // @ts-ignore
  const { contractAddress: main } = await publicClient.waitForTransactionReceipt({
    hash: mainHash,
  });
  // @ts-ignore
  const mainCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Main contract: ${main}, with nonce: ${mainCount}`);

  console.log("Deploying Business contract...");
  // @ts-ignore
  const businessHash = await walletClient.deployContract({
    abi: businessAbi,
    account: walletClient.account.address,
    bytecode: businessBytecode,
    args: [],
  });
  // @ts-ignore
  const { contractAddress: business } = await publicClient.waitForTransactionReceipt({
    hash: businessHash,
  });
  // @ts-ignore
  const businessCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Business contract: ${business}, with nonce: ${businessCount}`);

  console.log("Deploying Marketplace contract...");
  // @ts-ignore
  const marketplaceHash = await walletClient.deployContract({
    abi: marketplaceAbi,
    account: walletClient.account.address,
    bytecode: marketplaceBytecode,
    args: [main, business, authorization],
  });
  // @ts-ignore
  const { contractAddress: marketplace } = await publicClient.waitForTransactionReceipt({
    hash: marketplaceHash,
  });
  // @ts-ignore
  const marketplaceCount = await publicClient.getTransactionCount({
    address: walletClient.account.address,
  });
  console.log(`Marketplace contract: ${marketplace}, with nonce: ${marketplaceCount}`);

  console.log("Transferring ownership...");
  // @ts-ignore
  const creationContract = getContract({
    address: creation,
    abi: creationAbi,
    publicClient,
    walletClient,
  });
  // @ts-ignore
  const authorizationContract = getContract({
    address: authorization,
    abi: authorizationAbi,
    publicClient,
    walletClient,
  });
  // @ts-ignore
  const lockingVaultContract = getContract({
    address: lockingVault,
    abi: lockingVaultAbi,
    publicClient,
    walletClient,
  });
  console.log("Transferring creation contract ownership to main...");
  await sleep(5000);
  await creationContract.write.transferOwnership([main]);
  console.log("Transferring authorization contract ownership to main...");
  await sleep(5000);
  await authorizationContract.write.transferOwnership([main]);
  console.log("Transferring lockingVaultContract contract ownership to main...");
  await sleep(5000);
  await lockingVaultContract.write.transferOwnership([main]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    main,
    governance,
    creation,
    authorization,
    lockingVault,
    marketplace,
    business,
  };

  console.log(addresses);

  // Save the addresses to a file
  const folderPath = "address";

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
