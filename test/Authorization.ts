import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress } from "viem";

describe("Authorization", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, account1, account2] = await hre.viem.getWalletClients();

    // Depolyment
    const authorization = await hre.viem.deployContract("Authorization", [owner.account.address]);

    const publicClient = await hre.viem.getPublicClient();

    return {
      authorization,
      owner,
      account1,
      account2,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { authorization, owner } = await loadFixture(deployFixture);

      expect((await authorization.read.owner()).toLowerCase).to.equal(getAddress(owner.account.address).toLowerCase);
    });

    it("Should set the right name", async function () {
      const { authorization } = await loadFixture(deployFixture);

      expect(await authorization.read.name()).to.equal("Authorization");
    });

    it("Should set the right symbol", async function () {
      const { authorization } = await loadFixture(deployFixture);

      expect(await authorization.read.symbol()).to.equal("SMAT");
    });
  });

  describe("Mint", function () {
    it("Should revert with the mint error if address is 0", async function () {
      const { authorization, account1 } = await loadFixture(deployFixture);

      // Use other account to interact with the contract
      const contract = await hre.viem.getContractAt("Authorization", authorization.address, {
        walletClient: account1,
      });

      await expect(
        contract.write.mint([
          "0x0000000000000000000000000000000000000000",
          "https://en.sonarmeta.com/api/metadata/authorization/1",
        ])
      ).to.be.rejectedWith("Destination address can't be zero.");
    });

    it("Should mint a token successfully", async function () {
      const { authorization, account1, account2 } = await loadFixture(deployFixture);

      // Use other account to interact with the contract
      const contract = await hre.viem.getContractAt("Authorization", authorization.address, {
        walletClient: account1,
      });

      let tokenId = 1n;
      let uri = "https://en.sonarmeta.com/api/metadata/authorization/1";

      await contract.write.mint([getAddress(account2.account.address), uri]);

      expect(await contract.read.ownerOf([tokenId])).to.be.equal(getAddress(account2.account.address));
      expect(await contract.read.tokenURI([tokenId])).to.be.equal(uri);
      expect(await contract.read.balanceOf([getAddress(account2.account.address)])).to.be.equal(1n);

      tokenId = 2n;
      uri = "https://en.sonarmeta.com/api/metadata/authorization/2";

      await contract.write.mint([getAddress(account2.account.address), uri]);

      expect(await contract.read.ownerOf([tokenId])).to.be.equal(getAddress(account2.account.address));
      expect(await contract.read.tokenURI([tokenId])).to.be.equal(uri);
      expect(await contract.read.balanceOf([getAddress(account2.account.address)])).to.be.equal(2n);
    });
  });
});
