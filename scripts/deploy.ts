import hre from "hardhat";
import fs from "fs";
import path from "path";
import { createPublicClient, http } from "viem";
import { lineaTestnet } from "viem/chains";

async function main() {
  // Set before deployment
  const NETWORK = "LineaGoerli";

  const publicClient = createPublicClient({
    chain: lineaTestnet,
    transport: http(),
  });
  // Contracts are deployed using the first signer/account by default
  const [owner] = await hre.viem.getWalletClients();

  console.log("Deploying...");

  console.log("Deploying Creation contract...");
  // @ts-ignore
  let count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });

  const creation = await hre.viem.deployContract("Creation", [owner.account.address]);
  console.log(`Creation contract deployed at: ${creation.address}, with nonce ${count}`);

  console.log("Deploying Authorization contract...");
  // @ts-ignore
  count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });
  const authorization = await hre.viem.deployContract("Authorization", [
    "SonarMeta IP Network Edge",
    "SMINE",
    creation.address,
    owner.account.address,
  ]);
  console.log(`Authorization contract deployed at: ${authorization.address}, with nonce: ${count}`);

  console.log("Deploying LockingVault contract...");
  // @ts-ignore
  count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });
  const lockingVault = await hre.viem.deployContract("LockingVault", [owner.account.address, authorization.address]);
  console.log(`LockingVault contract deployed at: ${lockingVault.address}, with nonce: ${count}`);

  console.log("Deploying Marketplace contract...");
  // @ts-ignore
  count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });
  const marketplace = await hre.viem.deployContract("Marketplace", [authorization.address]);
  console.log(`Authorization contract deployed at: ${marketplace.address}, with nonce: ${count}`);

  console.log("Deploying Governance contract...");
  // @ts-ignore
  count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });
  const governance = await hre.viem.deployContract("Governance");
  console.log(`Authorization contract deployed at: ${governance.address}, with nonce: ${count}`);

  console.log("Deploying SonarMeta main contract...");
  // @ts-ignore
  count = await publicClient.getTransactionCount({
    address: owner.account.address,
  });
  const main = await hre.viem.deployContract("SonarMeta", [
    creation.address,
    authorization.address,
    lockingVault.address,
  ]);
  console.log(`Main contract deployed at: ${main.address}, with nonce: ${count}`);

  // Transfer Ownership
  await creation.write.transferOwnership([main.address]);
  await authorization.write.transferOwnership([main.address]);
  await lockingVault.write.transferOwnership([main.address]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    main: main.address,
    governance: governance.address,
    creation: creation.address,
    authorization: authorization.address,
    lockingVault: lockingVault.address,
    marketplace: marketplace.address,
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
