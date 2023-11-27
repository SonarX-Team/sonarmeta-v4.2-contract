import { TokenboundClient } from "@tokenbound/sdk";
import hre from "hardhat";

// This simulation points to
// https://github.com/SonarX-Team/sonarmeta-v4-next/blob/main/components/forms/TbaFactory.tsx
// https://www.sonarmeta.com/creations/<TokenId>/studio/tba

// SonarMeta Main contract implementation address
const main = "0x8083954F57e1f13edFEa9907971208F523Ec79e6";
// Creation contract implementation address
const creation = "0x755B6217f468DE6F8bd78Fd06eF34e7131D891B5";
// ERC-6551contract implementation address
const registryImp = "0xB6caCDa7c2Ce382D5Cc8d70F7C7f225aD3dEa642";
const tbaImp = "0x801b41437D7dbe15b8107bd5c75DA2A65Ed3fBE7";

const luksoChainId = 4201;

// Deploy the token-bound account corresponding to this creation token
// will allow the owner interact with its assets on behalf of it
async function deployTba({ tokenId }: { tokenId: `0x${string}` }) {
  const [wc] = await hre.viem.getWalletClients();

  const tokenboundClient = new TokenboundClient({
    // @ts-ignore
    walletClient: wc,
    chainId: luksoChainId,
    implementationAddress: tbaImp,
    registryAddress: registryImp,
  });

  // Calculate the TBA
  const creationTba = tokenboundClient.getAccount({
    tokenContract: creation,
    tokenId: tokenId,
  });

  // Check if the TBA has been already deployed
  const isAccountDeployed = await tokenboundClient.checkAccountDeployment({
    accountAddress: creationTba,
  });
  if (isAccountDeployed) return "The corresponding token-bound account of this creation has been already deployed!";

  // Deploy the TBA
  const { account, txHash } = await tokenboundClient.createAccount({
    tokenContract: creation,
    tokenId: tokenId,
  });

  return { account, txHash };
}

// Signing a TBA to SonarMeta makes us easy to track the relations among all TBAs
async function signTba({ tokenId }: { tokenId: `0x${string}` }) {
  const [wc] = await hre.viem.getWalletClients();

  const contract = await hre.viem.getContractAt("SonarMeta", main, {
    walletClient: wc,
  });

  const tokenboundClient = new TokenboundClient({
    // @ts-ignore
    walletClient: wc,
    chainId: luksoChainId,
    implementationAddress: tbaImp,
    registryAddress: registryImp,
  });

  // Calculate the TBA
  const creationTba = tokenboundClient.getAccount({
    tokenContract: creation,
    tokenId: tokenId,
  });

  await contract.write.signToUse([creationTba, tokenId]);
}

// Activating a TBA means that a TBA can be an authorization issuer
// This step will claim a new authorization tokenId corresponding to a creation tokenId
async function activateTba({ tokenId }: { tokenId: `0x${string}` }) {
  const [wc] = await hre.viem.getWalletClients();

  const contract = await hre.viem.getContractAt("SonarMeta", main, {
    walletClient: wc,
  });

  const tokenboundClient = new TokenboundClient({
    // @ts-ignore
    walletClient: wc,
    chainId: luksoChainId,
    implementationAddress: tbaImp,
    registryAddress: registryImp,
  });

  // Calculate the TBA
  const creationTba = tokenboundClient.getAccount({
    tokenContract: creation,
    tokenId: tokenId,
  });

  await contract.write.activateAuthorization([creationTba, tokenId]);
}

deployTba({ tokenId: "0x<Frontend router will give this param>" });
signTba({ tokenId: "0x<Frontend router will give this param>" });
activateTba({ tokenId: "0x<Frontend router will give this param>" });
