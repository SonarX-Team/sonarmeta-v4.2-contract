import { TokenboundClient } from "@tokenbound/sdk";
import hre from "hardhat";
import { formatEther, parseEther } from "viem";

// This simulation points to
// https://github.com/SonarX-Team/sonarmeta-v4-next/blob/main/components/forms/CreationListingItem.tsx
// https://www.sonarmeta.com/creations/5/studio/holders

// Authorization contract implementation address
const authorization = "0x5119629BB6364f377572880750DDd747d34Eac73";
// Marketplace contract implementation address
const marketplace = "0xA2aaf36403dD4C97749Fb6CA88e7d44f1E205f3c";
// ERC-6551contract implementation address
const registry = "0xB6caCDa7c2Ce382D5Cc8d70F7C7f225aD3dEa642";
const tokenbound = "0x801b41437D7dbe15b8107bd5c75DA2A65Ed3fBE7";

const luksoChainId = 4201;

// List authorization tokens by a token-bound account
// The list tx will execute by TBA's owner
async function createListing({
  tokenId,
  tbaAddr,
  amount,
  basePrice,
}: {
  tokenId: `0x${string}`;
  tbaAddr: `0x${string}`;
  amount: number;
  basePrice: number;
}) {
  const [wc] = await hre.viem.getWalletClients();

  const authorizationContract = await hre.viem.getContractAt("AuthorizationCollection", authorization, {
    walletClient: wc,
  });

  const tokenboundClient = new TokenboundClient({
    // @ts-ignore
    walletClient: wc,
    chainId: luksoChainId,
    implementationAddress: tokenbound,
    registryAddress: registry,
  });

  // This user need to approve the marketplace first
  authorizationContract.write.authorizeOperator([tbaAddr, tokenId, "0x"]);

  // Encode listItem function data
  //@ts-ignore
  const functionData = encodeFunctionData({
    abi: {
      inputs: [
        {
          internalType: "bytes32",
          name: "_tokenId",
          type: "bytes32",
        },
        {
          internalType: "uint256",
          name: "_amount",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "_basePrice",
          type: "uint256",
        },
      ],
      name: "listItem",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    functionName: "listItem",
    args: [tokenId, amount, parseEther(basePrice.toString())],
  });

  // As long as the wallet client is established by the current user
  // and the user is the token-bound account's owner
  // he/she can execute on behalf of the token-bound account
  const txHash = await tokenboundClient.execute({
    account: tbaAddr,
    to: marketplace,
    // @ts-ignore
    value: 0n,
    data: functionData,
  });
}

createListing({
  tokenId: "0x<Our database will provide this>",
  tbaAddr: "0x<Our database will provide this>",
  amount: 100, // Amount input by seller
  basePrice: 0.013, // Base price input by seller
});
