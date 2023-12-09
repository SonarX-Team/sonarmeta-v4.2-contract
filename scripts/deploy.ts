import hre from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  // Set before deployment
  const NETWORK = "polygonMumbai";
  const routerAddr: `0x${string}` = "0x70499c328e1e2a3c41108bd3730f6670a44595d1";
  const linkAddr: `0x${string}` = "0x326c977e6efc84e512bb9c30f76e30c160ed06fb";
  const sourceChainSelector = 14767482510784806043n;

  // Contracts are deployed using the first signer/account by default
  const [owner] = await hre.viem.getWalletClients();

  console.log("Deploying...");

  console.log("Deploying Creation contract...");
  const creation = await hre.viem.deployContract("Creation", [owner.account.address]);

  console.log("Deploying Authorization contract...");
  const authorization = await hre.viem.deployContract("Authorization", [owner.account.address]);

  console.log("Deploying Marketplace contract...");
  const marketplace = await hre.viem.deployContract("Marketplace", [authorization.address]);

  console.log("Deploying Governance contract...");
  const governance = await hre.viem.deployContract("Governance");

  console.log("Deploying SonarMeta main contract...");
  const main = await hre.viem.deployContract("SonarMeta", [creation.address, authorization.address]);

  console.log("Deploying CCIP message receiver contract...");
  const receiver = await hre.viem.deployContract("MessageReceiver", [routerAddr, linkAddr]);

  // Set CCIP receiver allow list
  receiver.write.allowlistSourceChain([sourceChainSelector, true]);

  // Transfer Ownership
  await creation.write.transferOwnership([main.address]);
  await authorization.write.transferOwnership([main.address]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    main: main.address,
    governance: governance.address,
    creation: creation.address,
    authorization: authorization.address,
    marketplace: marketplace.address,
    receiver: receiver.address,
  };

  console.log(addresses);

  // Save the addresses to a file
  const folderPath = "address/main";

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
