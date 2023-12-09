import hre from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  // Set before deployment
  const NETWORK = "avalancheFuji";
  const routerAddr: `0x${string}` = "0x554472a2720e5e7d5d3c817529aba05eed5f82d8";
  const sonarMetaAddr: `0x${string}` = "0xf464b8279c1d5d100e565164518fe636d9c0d442";

  console.log("Deploying...");

  console.log("Deploying CCIP message receiver contract...");
  const receiver = await hre.viem.deployContract("MessageReceiver", [routerAddr, sonarMetaAddr]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    receiver: receiver.address,
  };

  console.log(addresses);

  // Save the addresses to a file
  const folderPath = "address/receiver";

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
