import hre from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  const NETWORK = "arbitrumGoerli"; // Set before deployment

  console.log("Deploying...");

  console.log("Deploying Creation contract...");
  const creation = await hre.viem.deployContract("Creation");

  console.log("Deploying Authorization contract...");
  const authorization = await hre.viem.deployContract("Authorization");

  console.log("Deploying Registry contract...");
  const registry = await hre.viem.deployContract("ERC6551Registry");

  console.log("Deploying TBA contract...");
  const tba = await hre.viem.deployContract("ERC6551Account");

  console.log("Deploying Marketplace contract...");
  const marketplace = await hre.viem.deployContract("Marketplace", [authorization.address]);

  console.log("Deploying ChainlinkVRF contract...");
  const chainlinkVrf = await hre.viem.deployContract("ChainlinkVRF");

  console.log("Deploying Governance contract...");
  const governance = await hre.viem.deployContract("Governance");

  console.log("Deploying SonarMeta main contract...");
  const main = await hre.viem.deployContract("SonarMeta", [
    creation.address,
    authorization.address,
    registry.address,
    tba.address,
    marketplace.address,
    chainlinkVrf.address,
  ]);

  console.log("Deployed!");

  // Save the addresses
  const addresses = {
    main: main.address,
    governance: governance.address,
    creation: creation.address,
    authorization: authorization.address,
    marketplace: marketplace.address,
    registry: registry.address,
    tba: tba.address,
    chainlinkVrf: chainlinkVrf.address,
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
