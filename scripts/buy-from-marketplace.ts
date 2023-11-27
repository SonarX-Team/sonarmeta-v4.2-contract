import hre from "hardhat";
import { parseEther } from "viem";

// Marketplace contract implementation address
const marketplace = "0xA2aaf36403dD4C97749Fb6CA88e7d44f1E205f3c";

// Buy authorization tokens by any user
async function buyListing({
  tokenId,
  seller,
  amount,
  basePrice,
}: {
  tokenId: `0x${string}`;
  seller: `0x${string}`;
  amount: number;
  basePrice: number;
}) {
  const [wc] = await hre.viem.getWalletClients();

  const contract = await hre.viem.getContractAt("Marketplace", marketplace, {
    walletClient: wc,
  });

  await contract.write.buyItem([tokenId, seller, BigInt(amount)], {
    value: parseEther((basePrice * amount).toString()),
  });
}

buyListing({
  tokenId: "0x<Our database will provide this>",
  seller: "0x<Our database will provide this>",
  amount: 100, // Amount input by buyer
  basePrice: 0.013, // Base price from database
});
