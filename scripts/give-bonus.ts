import { TokenboundClient } from "@tokenbound/sdk";
import hre from "hardhat";

// This simulation points to
// https://github.com/SonarX-Team/sonarmeta-v4-next/blob/main/components/forms/Contribution.tsx
// https://www.sonarmeta.com/creations/5/studio/holders

// SonarMeta Main contract implementation address
const main = "0x8083954F57e1f13edFEa9907971208F523Ec79e6";
// Creation contract implementation address
const creation = "0x755B6217f468DE6F8bd78Fd06eF34e7131D891B5";
// ERC-6551contract implementation address
const registryImp = "0xB6caCDa7c2Ce382D5Cc8d70F7C7f225aD3dEa642";
const tbaImp = "0x801b41437D7dbe15b8107bd5c75DA2A65Ed3fBE7";

const luksoChainId = 4201;

// Give bonus from issuer node to holder node
async function giveBonus({
  holderTokenId,
  issuerTokenId,
  amount,
}: {
  holderTokenId: `0x${string}`;
  issuerTokenId: `0x${string}`;
  amount: number;
}) {
  const [wc] = await hre.viem.getWalletClients();

  const tokenboundClient = new TokenboundClient({
    // @ts-ignore
    walletClient: wc,
    chainId: luksoChainId,
    implementationAddress: tbaImp,
    registryAddress: registryImp,
  });

  // Calculate the holder node TBA
  const holder = tokenboundClient.getAccount({
    tokenContract: creation,
    tokenId: holderTokenId,
  });

  // Calculate the issuer node TBA
  const issuer = tokenboundClient.getAccount({
    tokenContract: creation,
    tokenId: issuerTokenId,
  });

  const contract = await hre.viem.getContractAt("SonarMeta", main, {
    walletClient: wc,
  });

  await contract.write.contribute([issuer, holder, issuerTokenId, BigInt(amount)]);
}

giveBonus({
  holderTokenId: "0x<Our database will provide this>",
  issuerTokenId: "0x<Our database will provide this>",
  amount: 100, // Amount input by issuer's owner
});
