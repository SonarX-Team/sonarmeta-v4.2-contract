import hre from "hardhat";
import { getAddress } from "viem";
import implmentations from "../address/address-lukso.json";

// This simulation points to
// https://github.com/SonarX-Team/sonarmeta-v4-next/blob/main/components/forms/CreateCreation.tsx.
// https://www.sonarmeta.com/create/creation

// User mint a creation is mint a network node on SonarMeta
// This is the first step with a creator
async function createCreation() {
  const [wc] = await hre.viem.getWalletClients();

  // SonarMeta Main contract implementation address
  const main = "0x8083954F57e1f13edFEa9907971208F523Ec79e6";

  const contract = await hre.viem.getContractAt("SonarMeta", main, {
    walletClient: wc,
  });

  await contract.write.mintCreation([getAddress(wc.account.address)]);
}

createCreation();
