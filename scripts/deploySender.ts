import hre from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  // Set before deployment
  const NETWORK = "avalancheFuji";
  const routerAddr: `0x${string}` = "0x554472a2720e5e7d5d3c817529aba05eed5f82d8";
  const sonarMetaAddr: `0x${string}` = "0xd7c68ffbcdae5ddc171af7d5b707f1f521253ae8"; // SET
  const destinationChainSelector = 12532609583862916517n;

  console.log("Deploying...");

  console.log("Deploying CCIP message sender contract...");
  const sender = await hre.viem.deployContract("MessageSender", [routerAddr, sonarMetaAddr]);

  // Set CCIP sender allow list
  sender.write.allowlistDestinationChain([destinationChainSelector, true]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    sender: sender.address,
  };

  console.log(addresses);

  // Save the addresses to a file
  const folderPath = "address/sender";

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
