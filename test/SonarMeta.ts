import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { TokenboundClient } from "@tokenbound/sdk";
import { expect } from "chai";
import hre from "hardhat";
import { hardhat } from "viem/chains";

describe("SonarMeta", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, account1, account2] = await hre.viem.getWalletClients();

    // Depolyment
    console.log("deploying creation");
    const creation = await hre.viem.deployContract("Creation", [owner.account.address]);
    console.log("deploying authorization");
    const authorization = await hre.viem.deployContract("Authorization", [owner.account.address]);
    console.log("deploying main");
    const main = await hre.viem.deployContract("SonarMeta", [creation.address, authorization.address]);

    // Transfer Ownership
    await creation.write.transferOwnership([main.address]);
    await authorization.write.transferOwnership([main.address]);

    const publicClient = await hre.viem.getPublicClient();

    return {
      main,
      creation,
      authorization,
      owner,
      account1,
      account2,
      publicClient,
    };
  }

  describe("Authorize", function () {
    it("Should work", async function () {
      const { main, creation, owner, account1, account2 } = await loadFixture(deployFixture);

      const fromTokenId = await main.write.mintCreation([account1.account.address]);
      const toTokenId = await main.write.mintCreation([account2.account.address]);

      const tokenboundClient = new TokenboundClient({ walletClient: owner, chain: hardhat });

      const { account: fromTba } = await tokenboundClient.createAccount({
        tokenContract: creation.address,
        tokenId: fromTokenId,
      });
      const { account: toTba } = await tokenboundClient.createAccount({
        tokenContract: creation.address,
        tokenId: toTokenId,
      });

      expect(await main.write.authorize([fromTba, toTba, fromTokenId])).to.equal(1n);
    });
  });
});
