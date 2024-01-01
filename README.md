# SonarMeta v4.3 EVM contracts

## Demo resources

- Demo website address: [https://www.sonarmeta.com](https://www.sonarmeta.com).
- Demo Next.js repo: [https://github.com/SonarX-Team/sonarmeta-v4-next/tree/viction](https://github.com/SonarX-Team/sonarmeta-v4-next/tree/viction).
- Demo video: [https://youtu.be/eT6uTgPD-d8](https://youtu.be/eT6uTgPD-d8)

## Address of deployment

### Viction Testnet

- SonarMeta main contract: 0xb4e25ef589a181390635cf00528d3d98fae14216
- Governance contract: 0x97818207b5ea2c41a0532c98592507751e9f106a
- Creation (network node) collection: 0xdeacf67c609dce96cc84460ce75c933bfe28fd4c
- Authorization (network edge) collection: 0x888e6435cef61c67a56e75447fa7bf6b021b86ec
- Locking Vault contract: 0x3dadf65562a69f20829c2b8e5da35c9e88860140
- Marketplace contract: 0x97ffa1634170c1eb705b384baf1aa2f690b236fc
- Business contract: 0x5eda45a740158d985854ebb408a41dae4e96de3b
- ERC-6551 Registry contract: 0xadeb40195e7abe1d1e5bd36d07960fc6835e3801
- ERC-6551 Tokenbound Account contract: 0xf92d5475190cde3f44df2f9d2bdc932f48e71fd4

## Vision

SonarMeta aims to create a metaverse entirely driven by the creator community, enabling creators to freely buy/sell VIEWs using tokenized authorizations without being constrained by the algorithms of Web2 centralized platforms. By authorizing derivatives of their works, creators build shareholder relationships with other creators, fostering P2P incentives and win-win scenarios, ultimately unlocking the full potential of each IP.

## Problem & Motivation

SonarMeta has always been interested in intellectual property (IP). Over the past decade, we have witnessed the glory of many Web2 content platforms. However, these platforms often manipulate VIEWs with algorithms for their own benefit, leading to the concentration of exposure opportunities, brand agencies, and social resources on the top-tier IPs. This results in many promising IPs not fully accessing resources and prematurely fading away. Creators' earnings are often unfair, and infringement issues are becoming increasingly severe. Despite these challenges, the global IP industry is expected to have a market value of trillions of dollars.

It's crucial to recognize that with the increasingly challenging employment landscape, growing unemployment rates, and the widespread use of AIGC tools, emerging IPs continue to emerge rapidly, and predicting their upper limit in quantity is nearly impossible. While top-tier IPs hold immense value, their quantity is very limited, and the potential of tail-end IPs should far surpass that of the top-tier IPs. On the internet, we often see small IPs unexpectedly gaining popularity in a short period due to triggering recommendation algorithms. However, not every IP is so fortunate, with many facing significant resource shortages, hindering them from unlocking their potential. Therefore, it is worth considering using blockchain as a tool to decentralize VIEWs distribution. If we can unleash the potential of IPs that prematurely faded away, the overall market value will far exceed the current estimates.

Therefore, SonarMeta aims to build a decentralized network centered around IP, ensuring that the value of IP can be captured and circulated. VIEWs distribution will be determined by the entire creator ecosystem rather than being constrained by Web2 content platforms. Copyright will be fully protected, forming a network of mutually beneficial relationships among IPs. Everyone becomes a shareholder in the IPs they contribute to, enjoying the deserved benefits.

## Core Mechanism

The key to enhancing the value of an IP lies in increasing its VIEWs. One straightforward method to acquire VIEWs is by authorizing others to create derivative works. Authorization is no longer merely a grant of legitimacy to derivatives; it is also a tool for trading VIEWs. High-value IPs can sell authorizations at a premium to unleash VIEWs, while low-value IPs can sell authorizations at a lower cost or even for free to attract VIEWs. In other words, as an IP becomes more valuable, its authorizations become more expensive, and the price and circulation of authorizations can reflect the IP's value.

Therefore, we tokenize authorizations, and holders contribute and provide VIEWs to the IP by creating derivatives (or any means, such as posting on Twitter), enhancing its value. Consequently, the value of their authorization tokens increases. This incentivizes the entire creator ecosystem to assist IPs facing early resource challenges in unlocking their potential.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe2034425037b33fa2246458eff6.png)

## Key Features

- **Tokenization of Authorization**: The market value and circulation of authorization tokens, serving as tools to safeguard IP copyrights and acquire VIEWs, reflect the value of the IP.
- **Growth Loop**: When authorization exchanges result in the flow of VIEWs to an IP, it signifies an increase in the IP's value. In turn, this enhances the value of its authorization (i.e., the capacity to exchange for VIEWs), creating a growth loop for IP value.
- **Incentive Model**: As the value of authorization tokens increases with the original IP's value, holders contributing efforts are essentially investing in themselves. This aligns with an incentive-compatible stakeholder capitalism model, initiating a cycle of node growth and addressing the core issue.
- **Value Network**: When derivatives also have their derivatives, an IP value network emerges, with creations as nodes and authorizations as edges.
- **Network Effects**: As each node is supported by actual VIEWs and has a growth cycle, we can infer that the entire network's value is real and growing. It exhibits clear network effects barriers, rather than heading towards a Ponzi scheme.
- **Universal Shareholders**: With the foundation of incentive compatibility established between originals and derivatives, blockchain is used to accurately trace each creator's contribution, ensuring that all network participants receive their deserved benefits.

## Technical Architecture

SonarMeta utilizes the concept of a token-bound account (TBA) mentioned in ERC-6551 to assist NFT creations in declaring their on-chain authorization entity status. Authorization tokens are issued and received by TBAs, designating the creation issuing the authorization as Original/Issuer and the creation receiving the authorization as Derivative/Holder.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe3dbfeba84121d07164602b59a6.png)

If a creation is a co-creation, its components (such as different layers of a painting or different tracks of a song) can all be minted as NFTs and submitted to the creation's Token-Bound Account (TBA). The creator's team can deploy an IP DAO contract to manage and index the contribution level of each contributor.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe432a1e7f79a0c627f494fa502a.png)

## A possible early application scenario

Emoji packs (i.e. stickers, memes) — Spread IP in the most lightweight and efficient way! Static images, when transformed into a sticker, can express various emotions, making them more appealing to a wider audience. They can be shared effortlessly on any social media platform and spread virally in a p2p manner, without relying on centralized B2C recommendation algorithms, aligning with our expectations. Creating a set of 20-30 stickers with a reference image, can have a production cycle of less than a month. It is much simpler compared to videos and games, making it easy to attract early creators. An emoji pack can serve as an NFT collection, which we are already familiar with.

Each creation node on SonarMeta is considered a basic IP image. An original can inspire a creator to mint a derivative node and deploy a separate NFT collection to mint stickers. The sticker NFTs are treated as components, added to the derivative node's token-bound account, applying for original authorization for the entire node. Now, the emoji pack can be distributed on any social media platform, such as Discord, Telegram, WeChat, allowing enthusiasts to freely share it. Due to the similarity between the derivative and the original, they can pass VIEWs value mutually, and the creator can consistently profit through reward coins. This innovative NFT gameplay continuously can introduce NFTs into the real world and increase the user base of Web3. Creators no longer need to rely on the limited transaction volume and low prices on platforms like Opensea to make a profit.

## Why blockchain?

Blockchain tokenization offers the ability to concretize and capture abstract value, and provides everyone with a fair investment opportunity, allowing for transparent asset tracking and accurate distribution of returns. Investment is not limited to currency; it can be any abstract entity, such as VIEWs of a tweet, video editing skills, team collaboration, and more. Leveraging these capabilities, we can closely integrate with the current creative economy, bringing people together, ensuring unimpeded value flow, and providing each person with their deserved returns. Ultimately, it unleashes a significant amount of untapped potential.

The immense value nurtured by the IP culture industry comes from a vast community of creators. We do not wish for these values to be monopolized by centralized platforms, subject to arbitrary exploitation, as relying on any centralized platform to be objective, fair, and efficient is an uncertain prospect. Existing platforms follow hierarchical structures, making it challenging for lower-tier creators to uphold their rights. Even if they manage to do so, the speed and cost are not optimistic. However, blockchain serves not only as a means of authentication but also as a highly concurrent, objective, transparent, and efficient method. It can automatically and rapidly address the rights and profit issues of a large number of creators without overlooking small IPs.

## For more infomation

[https://sonarx666.feishu.cn/docx/XyLndXhftoXz1GxkCYAcOIdrn1U?from=from_copylink](https://sonarx666.feishu.cn/docx/XyLndXhftoXz1GxkCYAcOIdrn1U?from=from_copylink)
